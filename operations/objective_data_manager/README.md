# Objective Data Manager

A lightweight CLI to collect and maintain the data needed to execute objectives:

- objective definitions
- permission/authorization records
- submission tracking
- government guarantee lending records
- full file inventory (name, size, modified time, hash)
- file-to-objective linking for situation-specific placement
- complete data export (`get-all-data`)
- progressive execution steps for acceleration (`add-execution-step`)
- authority and control matrix records (`add-control-matrix`)

## Usage

From the repository root:

```bash
python3 operations/objective_data_manager/objective_data_manager.py --store objective_data.json add-objective --id OBJ-001 --summary "Organize and execute submissions" --owner "Operations"
python3 operations/objective_data_manager/objective_data_manager.py --store objective_data.json add-permission --objective OBJ-001 --granted-by "Agency" --scope "Submit on behalf of org"
python3 operations/objective_data_manager/objective_data_manager.py --store objective_data.json add-submission --objective OBJ-001 --title "Q2 filing" --status "in_progress" --destination "Portal"
python3 operations/objective_data_manager/objective_data_manager.py --store objective_data.json add-lending-item --objective OBJ-001 --borrower "Small Business A" --amount 250000 --guarantee-type "SBA 7(a)" --status "pending"
python3 operations/objective_data_manager/objective_data_manager.py --store objective_data.json add-execution-step --objective OBJ-001 --step-id STEP-01 --title "Prepare submission package" --status "in_progress" --priority 10
python3 operations/objective_data_manager/objective_data_manager.py --store objective_data.json add-execution-step --objective OBJ-001 --step-id STEP-02 --title "Submit through authorized portal" --status "pending" --priority 20
python3 operations/objective_data_manager/objective_data_manager.py --store objective_data.json update-step-status --objective OBJ-001 --step-id STEP-02 --status "in_progress"
python3 operations/objective_data_manager/objective_data_manager.py --store objective_data.json add-control-matrix --pon "1984" --tas "Authorized" --approval-authority "Program Office" --execution-systems "Authorized Treasury systems" --custody "Regulated financial institutions" --oversight "Treasury, OMB, GAO"
python3 operations/objective_data_manager/objective_data_manager.py --store objective_data.json index-files --root .
python3 operations/objective_data_manager/objective_data_manager.py --store objective_data.json link-file --objective OBJ-001 --file-path "docs/filings/Q2.pdf" --situation "Quarterly filing" --target-location "submissions/quarterly" --notes "Upload first"
python3 operations/objective_data_manager/objective_data_manager.py --store objective_data.json organize-plan --objective OBJ-001
python3 operations/objective_data_manager/objective_data_manager.py --store objective_data.json get-all-data
python3 operations/objective_data_manager/objective_data_manager.py --store objective_data.json summary
```

## Notes

- Run `index-files` whenever your working files change and you need a refreshed inventory.
- Use `link-file` to map files to objective situations and target placement locations.
- Use `organize-plan` to produce a grouped placement plan by `target_location`.
- Use `add-execution-step` + `update-step-status` to drive progressive action plans and track active execution.
- Use `add-control-matrix` to preserve authority/control metadata for compliance evidence.
- The datastore is plain JSON so it can be reviewed, versioned, or synced into a larger workflow.
