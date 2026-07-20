# FAQ

### 1. What is GoalfyData?

GoalfyData is a governed data layer for AI agents. It stores data together with field definitions, relationships, metrics, rules, permissions, and usage guidance, so different agents can query, update, and reuse it consistently.

### 2. Is GoalfyData a database?

No. GoalfyData does not replace databases or spreadsheets such as MySQL, Excel, Airtable, or Feishu Sheets. It adds a governed context layer that helps agents understand where data is stored, what fields mean, how tables are related, how metrics are calculated, and what data they are allowed to access.

### 3. How is GoalfyData different from spreadsheets, databases, and BI dashboards?

Spreadsheets and databases store data, while BI dashboards present results. GoalfyData adds the structure, definitions, relationships, update rules, permissions, and usage guidance that agents need to use the data consistently. This turns data into an asset that agents can query, update, and reuse.

### 4. Which agents can I use GoalfyData with?

GoalfyData currently provides setup guides for Codex, Claude Code, Manus, and MCP/CLI workflows. Connected agents can query datasets, update data, generate reports, and build dashboards or apps without requiring you to upload the same files and explain the same rules again.

### 5. What is stored in a dataset?

A GoalfyData dataset can include tables, field definitions, primary keys, table relationships, field mappings, metric definitions, processing rules, update methods, usage guidance, permissions, and sharing settings. This helps agents understand both the data and how it should be used.

### 6. What is a GoalfyData Managed Refresh?

A Managed Refresh is an automated job run by GoalfyData to update a dataset in an isolated environment. The time required depends on the data size, source complexity, and refresh logic.

### 7. What does not count as a Managed Refresh?

Agent edits, standard dataset queries, MCP writes, and app reads do not count as Managed Refreshes unless they start a GoalfyData-managed refresh job.

### 8. What does "apps" mean?

Apps is the total number of apps you own, including dashboards and lightweight apps built from your datasets. Online, offline, and failed apps all count — only deleting an app frees a slot.

### 9. How are plan quotas and add-on packs calculated?

Plan quotas reset every 30 days. Add-on quotas are valid for 30 days from purchase and expire if unused. We use your plan quota first, followed by the matching add-on quota.

### 10. How many datasets can I create on each plan?

The Free plan includes 3 datasets, Standard includes 20, and Pro includes 100. Dataset usage is counted in 300 MB blocks.

### 11. What does one dataset include?

Each dataset includes up to 300 MB. Larger datasets use additional dataset quota in 300 MB blocks.

### 12. What happens if my dataset is larger than 300MB?

You can create a dataset larger than 300 MB, but it will use more than one unit of your dataset quota. For example, a 900 MB dataset uses 3 dataset units.

### 13. Do datasets shared with me count toward my limit?

Viewing a sharing invitation does not affect your limit. After you accept the invitation and add the dataset to your workspace, it counts toward your dataset quota.

### 14. What happens when I reach my plan limit?

You can upgrade your plan or buy an add-on for datasets, Managed Refreshes, or published apps. Reaching a limit does not delete your existing datasets or apps.

### 15. Can Free users buy add-on packs on their own?

No. Add-ons are available only on Standard and Pro. If you are on the Free plan, upgrade before purchasing additional datasets, Managed Refreshes, or published apps.

### 16. Is my data safe?

Your private workspace data is not public by default. You can control access to datasets, apps, and agents through permissions and sharing settings. Only the members, apps, links, and agents you authorize can access the corresponding data.
