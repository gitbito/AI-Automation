#!/usr/bin/env python3
"""Objective data manager.

Builds a local index of files and tracks objectives, permissions, submissions,
and government-guaranteed lending items in a single JSON datastore.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

EXCLUDED_DIR_NAMES = {".git", "node_modules", ".venv", "venv", "__pycache__"}
DEFAULT_DATASTORE = "objective_data.json"


@dataclass
class Submission:
    objective_id: str
    title: str
    status: str
    destination: str
    due_date: str | None
    notes: str | None
    created_at: str


@dataclass
class LendingItem:
    objective_id: str
    borrower: str
    amount: float
    guarantee_type: str
    status: str
    reference: str | None
    created_at: str


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def ensure_schema(data: dict[str, Any]) -> dict[str, Any]:
    """Ensure datastore includes all required keys across versions."""
    data.setdefault("created_at", now_iso())
    data.setdefault("updated_at", now_iso())
    data.setdefault("objectives", {})
    data.setdefault("permissions", [])
    data.setdefault("submissions", [])
    data.setdefault("government_guarantee_lending", [])
    data.setdefault("file_index", {})
    data.setdefault("objective_file_links", [])
    data.setdefault("execution_steps", [])
    data.setdefault("authority_control_matrix", [])
    return data


class ObjectiveStore:
    def __init__(self, path: Path) -> None:
        self.path = path
        self.data = self._load()

    def _load(self) -> dict[str, Any]:
        if not self.path.exists():
            return ensure_schema({})

        with self.path.open("r", encoding="utf-8") as handle:
            return ensure_schema(json.load(handle))

    def save(self) -> None:
        self.data["updated_at"] = now_iso()
        with self.path.open("w", encoding="utf-8") as handle:
            json.dump(self.data, handle, indent=2, ensure_ascii=False)

    def add_objective(self, objective_id: str, summary: str, owner: str | None, status: str) -> None:
        existing = self.data["objectives"].get(objective_id, {})
        created_at = existing.get("created_at", now_iso())
        self.data["objectives"][objective_id] = {
            "summary": summary,
            "owner": owner,
            "status": status,
            "created_at": created_at,
            "updated_at": now_iso(),
        }

    def add_permission(self, objective_id: str, granted_by: str, scope: str, expires_on: str | None) -> None:
        self.data["permissions"].append(
            {
                "objective_id": objective_id,
                "granted_by": granted_by,
                "scope": scope,
                "expires_on": expires_on,
                "created_at": now_iso(),
            }
        )

    def add_submission(self, submission: Submission) -> None:
        self.data["submissions"].append(asdict(submission))

    def add_lending_item(self, lending_item: LendingItem) -> None:
        self.data["government_guarantee_lending"].append(asdict(lending_item))

    def link_file(
        self,
        objective_id: str,
        file_path: str,
        situation: str,
        target_location: str,
        notes: str | None,
    ) -> None:
        self.data["objective_file_links"].append(
            {
                "objective_id": objective_id,
                "file_path": file_path,
                "situation": situation,
                "target_location": target_location,
                "notes": notes,
                "created_at": now_iso(),
            }
        )

    def rebuild_file_index(self, root: Path) -> int:
        index: dict[str, Any] = {}
        for path in root.rglob("*"):
            if not path.is_file():
                continue
            if any(part in EXCLUDED_DIR_NAMES for part in path.parts):
                continue

            relative_path = str(path.relative_to(root))
            stats = path.stat()
            index[relative_path] = {
                "size_bytes": stats.st_size,
                "modified_at": datetime.fromtimestamp(stats.st_mtime, tz=timezone.utc).isoformat(),
                "sha256": file_hash(path),
            }

        self.data["file_index"] = index
        return len(index)

    def add_execution_step(
        self,
        objective_id: str,
        step_id: str,
        title: str,
        status: str,
        priority: int,
        notes: str | None,
    ) -> None:
        self.data["execution_steps"] = [
            step
            for step in self.data["execution_steps"]
            if not (step["objective_id"] == objective_id and step["step_id"] == step_id)
        ]
        self.data["execution_steps"].append(
            {
                "objective_id": objective_id,
                "step_id": step_id,
                "title": title,
                "status": status,
                "priority": priority,
                "notes": notes,
                "updated_at": now_iso(),
            }
        )

    def set_step_status(self, objective_id: str, step_id: str, status: str) -> None:
        for step in self.data["execution_steps"]:
            if step["objective_id"] == objective_id and step["step_id"] == step_id:
                step["status"] = status
                step["updated_at"] = now_iso()
                return
        raise SystemExit(f"Step '{step_id}' not found for objective '{objective_id}'.")

    def add_control_matrix(
        self,
        pon: str,
        tas: str,
        approval_authority: str,
        execution_systems: str,
        custody: str,
        oversight: str,
        notes: str | None,
    ) -> None:
        self.data["authority_control_matrix"].append(
            {
                "pon": pon,
                "tas": tas,
                "approval_authority": approval_authority,
                "execution_systems": execution_systems,
                "custody": custody,
                "oversight": oversight,
                "notes": notes,
                "created_at": now_iso(),
            }
        )

    def objective_snapshot(self, objective_id: str) -> dict[str, Any]:
        validate_objective_exists(self, objective_id)
        return {
            "objective_id": objective_id,
            "objective": self.data["objectives"][objective_id],
            "permissions": [
                permission
                for permission in self.data["permissions"]
                if permission["objective_id"] == objective_id
            ],
            "submissions": [
                submission
                for submission in self.data["submissions"]
                if submission["objective_id"] == objective_id
            ],
            "government_guarantee_lending": [
                lending
                for lending in self.data["government_guarantee_lending"]
                if lending["objective_id"] == objective_id
            ],
            "file_links": [
                link
                for link in self.data["objective_file_links"]
                if link["objective_id"] == objective_id
            ],
            "execution_steps": sorted(
                [
                    step
                    for step in self.data["execution_steps"]
                    if step["objective_id"] == objective_id
                ],
                key=lambda item: (item["status"] != "in_progress", item["priority"]),
            ),
        }


def file_hash(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(8192), b""):
            digest.update(chunk)
    return digest.hexdigest()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Collect and organize objective data, permission records, file inventory, "
            "submissions, and government-guaranteed lending entries."
        )
    )
    parser.add_argument("--store", default=DEFAULT_DATASTORE, help="Path to datastore JSON")
    subparsers = parser.add_subparsers(dest="command", required=True)

    add_objective = subparsers.add_parser("add-objective", help="Create or update an objective")
    add_objective.add_argument("--id", required=True, help="Objective identifier")
    add_objective.add_argument("--summary", required=True, help="Objective summary")
    add_objective.add_argument("--owner", help="Objective owner")
    add_objective.add_argument("--status", default="active", help="Objective status")

    add_permission = subparsers.add_parser("add-permission", help="Record a permission grant")
    add_permission.add_argument("--objective", required=True, help="Objective identifier")
    add_permission.add_argument("--granted-by", required=True, help="Authority granting permission")
    add_permission.add_argument("--scope", required=True, help="Permission scope")
    add_permission.add_argument("--expires-on", help="Optional expiration date (YYYY-MM-DD)")

    add_submission = subparsers.add_parser("add-submission", help="Record a submission")
    add_submission.add_argument("--objective", required=True, help="Objective identifier")
    add_submission.add_argument("--title", required=True, help="Submission title")
    add_submission.add_argument("--status", required=True, help="Submission status")
    add_submission.add_argument("--destination", required=True, help="Submission destination")
    add_submission.add_argument("--due-date", help="Optional due date (YYYY-MM-DD)")
    add_submission.add_argument("--notes", help="Optional notes")

    add_lending = subparsers.add_parser(
        "add-lending-item",
        help="Record government guarantee lending information",
    )
    add_lending.add_argument("--objective", required=True, help="Objective identifier")
    add_lending.add_argument("--borrower", required=True, help="Borrower organization")
    add_lending.add_argument("--amount", required=True, type=float, help="Amount requested")
    add_lending.add_argument("--guarantee-type", required=True, help="Guarantee type")
    add_lending.add_argument("--status", required=True, help="Current status")
    add_lending.add_argument("--reference", help="Optional external reference")

    add_execution_step = subparsers.add_parser(
        "add-execution-step",
        help="Add or update a progressive action step for an objective",
    )
    add_execution_step.add_argument("--objective", required=True, help="Objective identifier")
    add_execution_step.add_argument("--step-id", required=True, help="Stable step identifier")
    add_execution_step.add_argument("--title", required=True, help="Step title")
    add_execution_step.add_argument("--status", default="pending", help="Step status")
    add_execution_step.add_argument("--priority", type=int, default=100, help="Lower number = higher priority")
    add_execution_step.add_argument("--notes", help="Optional execution notes")

    update_step_status = subparsers.add_parser(
        "update-step-status",
        help="Update the status of an execution step",
    )
    update_step_status.add_argument("--objective", required=True, help="Objective identifier")
    update_step_status.add_argument("--step-id", required=True, help="Step identifier")
    update_step_status.add_argument("--status", required=True, help="New step status")

    control_matrix = subparsers.add_parser(
        "add-control-matrix",
        help="Record authority and control matrix metadata",
    )
    control_matrix.add_argument("--pon", required=True, help="Program office number")
    control_matrix.add_argument("--tas", required=True, help="Treasury account symbol")
    control_matrix.add_argument("--approval-authority", required=True, help="Approval authority")
    control_matrix.add_argument("--execution-systems", required=True, help="Authorized execution systems")
    control_matrix.add_argument("--custody", required=True, help="Custody authority")
    control_matrix.add_argument("--oversight", required=True, help="Oversight authorities")
    control_matrix.add_argument("--notes", help="Optional notes")

    link_file = subparsers.add_parser(
        "link-file",
        help="Link a file to an objective and situation for placement/organization",
    )
    link_file.add_argument("--objective", required=True, help="Objective identifier")
    link_file.add_argument("--file-path", required=True, help="Indexed file path")
    link_file.add_argument("--situation", required=True, help="Context or situation for this file")
    link_file.add_argument("--target-location", required=True, help="Where this file should be placed")
    link_file.add_argument("--notes", help="Optional notes")

    index_files = subparsers.add_parser("index-files", help="Rebuild file inventory")
    index_files.add_argument("--root", default=".", help="Root directory to scan")

    get_all_data = subparsers.add_parser("get-all-data", help="Print full datastore JSON")
    get_all_data.add_argument("--objective", help="Optional objective id to filter output")

    organize_plan = subparsers.add_parser(
        "organize-plan",
        help="Print file placement plan grouped by target location",
    )
    organize_plan.add_argument("--objective", required=True, help="Objective identifier")

    subparsers.add_parser("summary", help="Print dataset summary")

    return parser.parse_args()


def validate_objective_exists(store: ObjectiveStore, objective_id: str) -> None:
    if objective_id not in store.data["objectives"]:
        raise SystemExit(f"Objective '{objective_id}' does not exist. Add it first with add-objective.")


def print_summary(store: ObjectiveStore) -> None:
    print("Datastore:", store.path)
    print("Objectives:", len(store.data["objectives"]))
    print("Permissions:", len(store.data["permissions"]))
    print("Submissions:", len(store.data["submissions"]))
    print("Government guarantee lending items:", len(store.data["government_guarantee_lending"]))
    print("Indexed files:", len(store.data["file_index"]))
    print("Linked files:", len(store.data["objective_file_links"]))
    print("Execution steps:", len(store.data["execution_steps"]))
    print("Authority/control records:", len(store.data["authority_control_matrix"]))


def print_json(payload: dict[str, Any]) -> None:
    print(json.dumps(payload, indent=2, ensure_ascii=False))


def print_organize_plan(store: ObjectiveStore, objective_id: str) -> None:
    snapshot = store.objective_snapshot(objective_id)
    grouped: dict[str, list[dict[str, Any]]] = {}
    for link in snapshot["file_links"]:
        target = link["target_location"]
        entry = {
            "file_path": link["file_path"],
            "situation": link["situation"],
            "notes": link["notes"],
            "indexed": link["file_path"] in store.data["file_index"],
        }
        grouped.setdefault(target, []).append(entry)

    print_json(
        {
            "objective_id": objective_id,
            "target_locations": grouped,
            "steps": snapshot["execution_steps"],
        }
    )


def main() -> None:
    args = parse_args()
    store = ObjectiveStore(Path(args.store))

    if args.command == "add-objective":
        store.add_objective(objective_id=args.id, summary=args.summary, owner=args.owner, status=args.status)
        store.save()
        print(f"Objective '{args.id}' saved.")
        return

    if args.command == "add-permission":
        validate_objective_exists(store, args.objective)
        store.add_permission(
            objective_id=args.objective,
            granted_by=args.granted_by,
            scope=args.scope,
            expires_on=args.expires_on,
        )
        store.save()
        print("Permission saved.")
        return

    if args.command == "add-submission":
        validate_objective_exists(store, args.objective)
        submission = Submission(
            objective_id=args.objective,
            title=args.title,
            status=args.status,
            destination=args.destination,
            due_date=args.due_date,
            notes=args.notes,
            created_at=now_iso(),
        )
        store.add_submission(submission)
        store.save()
        print("Submission saved.")
        return

    if args.command == "add-lending-item":
        validate_objective_exists(store, args.objective)
        lending_item = LendingItem(
            objective_id=args.objective,
            borrower=args.borrower,
            amount=args.amount,
            guarantee_type=args.guarantee_type,
            status=args.status,
            reference=args.reference,
            created_at=now_iso(),
        )
        store.add_lending_item(lending_item)
        store.save()
        print("Lending item saved.")
        return

    if args.command == "add-execution-step":
        validate_objective_exists(store, args.objective)
        store.add_execution_step(
            objective_id=args.objective,
            step_id=args.step_id,
            title=args.title,
            status=args.status,
            priority=args.priority,
            notes=args.notes,
        )
        store.save()
        print("Execution step saved.")
        return

    if args.command == "update-step-status":
        validate_objective_exists(store, args.objective)
        store.set_step_status(
            objective_id=args.objective,
            step_id=args.step_id,
            status=args.status,
        )
        store.save()
        print("Execution step status updated.")
        return

    if args.command == "add-control-matrix":
        store.add_control_matrix(
            pon=args.pon,
            tas=args.tas,
            approval_authority=args.approval_authority,
            execution_systems=args.execution_systems,
            custody=args.custody,
            oversight=args.oversight,
            notes=args.notes,
        )
        store.save()
        print("Authority/control matrix record saved.")
        return

    if args.command == "link-file":
        validate_objective_exists(store, args.objective)
        store.link_file(
            objective_id=args.objective,
            file_path=args.file_path,
            situation=args.situation,
            target_location=args.target_location,
            notes=args.notes,
        )
        store.save()
        print("File link saved.")
        return

    if args.command == "index-files":
        count = store.rebuild_file_index(Path(args.root).resolve())
        store.save()
        print(f"Indexed {count} files.")
        return

    if args.command == "get-all-data":
        if args.objective:
            print_json(store.objective_snapshot(args.objective))
            return
        print_json(store.data)
        return

    if args.command == "organize-plan":
        print_organize_plan(store, args.objective)
        return

    if args.command == "summary":
        print_summary(store)


if __name__ == "__main__":
    main()
