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
- auto-charge agreements (`add-auto-charge-agreement`)
- custody intake and pledge reconciliation records (`add-custody-intake`)

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
python3 operations/objective_data_manager/objective_data_manager.py --store objective_data.json add-auto-charge-agreement --objective OBJ-001 --agreement-id AC-BOFA-USB-001 --provider "BaaS Workflow" --counterparty-bank "Bank of America" --master-account-bank "U.S. Bank" --currency USD --status active --notes "No cap; auto-charge settlement profile"
python3 operations/objective_data_manager/objective_data_manager.py --store objective_data.json add-custody-intake --objective OBJ-001 --security-name "US Treasury Note 4.25% 2033" --asset-type bond --quantity 1000 --notional-amount 1000000 --currency USD --custody-bank "Bank of America" --intake-channel treasury --pledge-mail-account "mailbox://pledge/obj-001" --reconciliation-basis dollar_for_dollar --reference "CUSIP-EXAMPLE"
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
- Use `add-auto-charge-agreement` to capture provider, counterparty, master account, and optional cap amount (omit cap for no-cap agreements).
- Use `add-custody-intake` to track treasury/security intake, custody bank, pledge mail account, and dollar-for-dollar reconciliation basis.
- The datastore is plain JSON so it can be reviewed, versioned, or synced into a larger workflow.

## Security identifiers to track for leverage workflows

When objectives include collateral, margin, or other leverage-dependent workflows, keep these identifiers for each security:

- Ticker symbol (exchange symbol)
- CUSIP (US/Canada, 9-character issue identifier)
- ISIN (12-character international identifier)
- FIGI (open global instrument identifier)
- SEDOL (UK-focused instrument identifier)
- LEI (issuer-level legal entity identifier)

Recommended record shape:

```json
{
  "security_name": "Example Corp 5.25% 2031",
  "asset_type": "bond",
  "ticker": "EXMPL",
  "cusip": "123456AB7",
  "isin": "US123456AB78",
  "figi": "BBG000B9XRY4",
  "sedol": "0263494",
  "issuer_lei": "5493001KJTIIGC8Y1R12",
  "notes": "Primary collateral candidate for objective OBJ-001"
}
```
