# KQL queries by deck, on the four network tables

Companion to **01-KQL.pptx** and **02-KQL.pptx**. Every topic that has a query in those decks appears here **in slide order**,
with **three examples** that run on the four tables loaded in the lab workspace and nothing else:

| Table | What it holds |
|---|---|
| `Palo_FW_CL` | Palo Alto firewall traffic and threat logs |
| `Infoblox_DNS_CL` | Infoblox DNS queries, failures and zone events |
| `Infoblox_DHCP_CL` | Infoblox DHCP requests, leases and acknowledgements |
| `Netscaler_Logs_CL` | NetScaler session, HTTP and appliance events |

**Coverage:** 168 topics, 504 queries. Each query was executed against the workspace and returns without errors.
Slide numbers refer to each deck (`01` = 01-KQL.pptx, `02` = 02-KQL.pptx).

## Notes before you present

- **Original tables replaced.** The slides use `SecurityEvent`, `Heartbeat`, `Perf`, `SigninLogs`, `CommonSecurityLog` and similar; they are replaced here by the four tables above. Where a slide's example relies on a column the network tables do not have (for example JSON properties), a close equivalent is built with `bag_pack()` / `make_list()`.
- **Time windows.** The lab data is a **static sample from 2026-11-16 (UTC)**. Examples use `ago(30d)` so they return rows for a month after the load; `ago(1h)` or `ago(1d)` will return nothing once the sample is older than that. If a query returns no rows, widen the window or use an exact one:

```kusto
| where TimeGenerated between (datetime(2026-11-16 00:00:00) .. datetime(2026-11-17 00:00:00))
```

- **search and union stay scoped.** `search *` and `union *` would read every table in the workspace, so the examples use `search in (...)`, explicit table lists or the prefixes `Infoblox_*`, `Palo*` and `Netscaler*`, which resolve only to your tables.
- **Cross-workspace** examples (`workspace(...)`) point at the same lab workspace (MSLearn-Sentinel) so they still use only these tables.
- **`externaldata` and `adx()`** (slide 61 of 01) read data outside Log Analytics. `externaldata` is demonstrated with `datatable`, the inline equivalent; `adx()` has no equivalent on these tables and is not repeated.
- **Slides without a query** (agenda, structure, Log Analytics concepts, the data lake and retention material in 01, the module overview and section slides in 02) are not listed.
- **Charts:** `render` examples return the table and draw the chart in the portal's Chart view. The lab sample spans seconds to minutes, so bins are 1s to 1m.
- **Lab dataset only:** IPs, hostnames and domains come from the customer sample. Do not share the file outside the engagement without sanitizing.

## Contents

- **Part 1 · 01-KQL.pptx (Log Analytics workshop)**
  - 1. Log Analytics interface and demonstration (slides 40, 72–80)
  - 2. Kusto Queries 101 (slides 41–64)
- **Part 2 · 02-KQL.pptx (Using KQL)**
  - 3. Filtering with KQL (slides 5–10)
  - 4. Analyzing with KQL (slides 11–19)
  - 5. Presenting with KQL (slides 20–23)
  - 6. Advanced KQL operations (slides 24–33)
  - 7. Optimizing queries (slides 34–45)

---

## Part 1 · 01-KQL.pptx (Log Analytics workshop)


### 1. Log Analytics interface and demonstration (slides 40, 72–80)

#### 1.1 Run a simple query and adjust the time range

*01-KQL.pptx · slide 40, 80* — Time range from the picker, hard-coded with ago(), or an exact window.

**Example 1 · Simple query: the time range comes from the picker**

```kusto
Palo_FW_CL
| take 10
```

**Example 2 · Time range written in the query**

```kusto
Palo_FW_CL
| where TimeGenerated > ago(30d)
| take 10
```

**Example 3 · Exact time window**

```kusto
Infoblox_DNS_CL
| where TimeGenerated between (datetime(2026-11-16 19:50:00) .. datetime(2026-11-16 20:00:00))
| take 10
```

#### 1.2 Multiple tabs: one question per tab

*01-KQL.pptx · slide 40, 73* — Open a separate tab for each query and compare results side by side.

**Example 1 · Tab 1: what did the firewall block?**

```kusto
Palo_FW_CL
| where Action in ("deny", "reset-both", "block-url")
| project TimeGenerated, SrcIP, DestIP, DestPort, App, Rule
```

**Example 2 · Tab 2: which DNS lookups failed?**

```kusto
Infoblox_DNS_CL
| where EventType == "QueryFailure"
| project TimeGenerated, ClientIP, DnsQuery, FailureReason
```

**Example 3 · Tab 3: what happened on the NetScaler?**

```kusto
Netscaler_Logs_CL
| where Module == "APPFW"
| project TimeGenerated, DeviceName, EventType, Payload
```

#### 1.3 Schema view: find the right table and field

*01-KQL.pptx · slide 40, 74, 76* — getschema returns every column and its type, the same information as the Tables pane.

**Example 1 · All columns of a table**

```kusto
Palo_FW_CL
| getschema
```

**Example 2 · Only the name and type**

```kusto
Infoblox_DNS_CL
| getschema
| project ColumnName, ColumnType
```

**Example 3 · Find the address and port columns**

```kusto
Netscaler_Logs_CL
| getschema
| where ColumnName contains "IP" or ColumnName contains "Port"
| project ColumnName, ColumnType
```

#### 1.4 Row explorer: right-click to include or exclude a value

*01-KQL.pptx · slide 40, 78, 80* — The right-click menu adds a where line; these are the equivalent hand-written filters.

**Example 1 · Include a value (right-click, Include)**

```kusto
Palo_FW_CL
| where Action == "deny"
```

**Example 2 · Exclude a value (right-click, Exclude)**

```kusto
Palo_FW_CL
| where App != "dns-base"
```

**Example 3 · Include one value and exclude another**

```kusto
Infoblox_DHCP_CL
| where EventType == "DHCPACK"
| where ClientHostname != ""
```

#### 1.5 Hard-code the UI choices in KQL: lookback, columns, grouping

*01-KQL.pptx · slide 78* — Time range = where TimeGenerated, columns = project, Group columns = summarize.

**Example 1 · Lookback**

```kusto
Palo_FW_CL
| where TimeGenerated > ago(30d)
```

**Example 2 · Columns**

```kusto
Infoblox_DNS_CL
| project TimeGenerated, ClientIP, DnsQuery, QueryType
```

**Example 3 · Grouping**

```kusto
Netscaler_Logs_CL
| summarize Events = count() by Module, EventType
```

#### 1.6 Functions: saved queries recalled like a table

*01-KQL.pptx · slide 76* — Save a query with an alias (Save as function) and call it by name. Shown here as let functions so they run anywhere.

**Example 1 · A function without parameters**

```kusto
let GetBlockedTraffic = () {
    Palo_FW_CL
    | where Action in ("deny", "reset-both", "block-url")
};
GetBlockedTraffic()
| take 10
```

**Example 2 · A function with a parameter**

```kusto
let GetClientDns = (client: string) {
    Infoblox_DNS_CL
    | where ClientIP == client
    | project TimeGenerated, DnsQuery, QueryType
};
GetClientDns("10.192.132.14")
| take 10
```

**Example 3 · A function used as a parser**

```kusto
let GetDhcpHistory = (ip: string) {
    Infoblox_DHCP_CL
    | where LeaseIP == ip
    | project TimeGenerated, EventType, LeaseIP, ClientMAC, ClientHostname
};
GetDhcpHistory("10.216.132.166")
| sort by TimeGenerated desc
```

#### 1.7 Built-in parsing: right-click, Extend column

*01-KQL.pptx · slide 79* — The UI writes the parsing for you; these are the equivalent expressions on text columns.

**Example 1 · Split a text value into parts**

```kusto
Netscaler_Logs_CL
| where isnotempty(Duration)
| extend DurationParts = split(Duration, ":")
| extend Seconds = toint(DurationParts[2])
| project TimeGenerated, Duration, Seconds
| take 10
```

**Example 2 · Parse a formatted date string**

```kusto
Netscaler_Logs_CL
| where isnotempty(SessionStart)
| parse SessionStart with Month "/" Day "/" Year ":" Clock " GMT"
| project TimeGenerated, SessionStart, Month, Day, Year, Clock
| take 10
```

**Example 3 · Extract a number from message text**

```kusto
Netscaler_Logs_CL
| where Payload has "errno"
| extend ErrNo = toint(extract("errno: ([0-9]+)", 1, Payload))
| project TimeGenerated, ErrNo, Payload
| take 10
```

#### 1.8 UTC to local time conversion

*01-KQL.pptx · slide 80* — TimeGenerated is UTC; convert it for display when you need local time.

**Example 1 · Mountain time**

```kusto
Palo_FW_CL
| extend LocalTime = datetime_utc_to_local(TimeGenerated, "America/Edmonton")
| project TimeGenerated, LocalTime, SrcIP, DestIP
| take 5
```

**Example 2 · Eastern time**

```kusto
Infoblox_DNS_CL
| extend LocalTime = datetime_utc_to_local(TimeGenerated, "America/Toronto")
| project TimeGenerated, LocalTime, ClientIP, DnsQuery
| take 5
```

**Example 3 · A readable local timestamp**

```kusto
Infoblox_DHCP_CL
| extend LocalTime = format_datetime(datetime_utc_to_local(TimeGenerated, "America/Edmonton"), "yyyy-MM-dd HH:mm:ss")
| project LocalTime, EventType, LeaseIP
| take 5
```


### 2. Kusto Queries 101 (slides 41–64)

#### 2.1 What is Kusto? Tabular, piped, read-only

*01-KQL.pptx · slide 42* — A table name is already a query; each pipe adds a step; nothing is modified.

**Example 1 · A table is a query**

```kusto
Infoblox_DHCP_CL
| take 5
```

**Example 2 · Piped expression**

```kusto
Palo_FW_CL
| where Action == "deny"
| count
```

**Example 3 · Dozens of built-in functions**

```kusto
Infoblox_DNS_CL
| extend NameLength = strlen(DnsQuery)
| top 5 by NameLength
| project DnsQuery, NameLength
```

#### 2.2 Understanding the pipeline

*01-KQL.pptx · slide 43* — Each step only sees the output of the step before it: data, filter, analyze, present.

**Example 1 · Firewall: who has the most allowed sessions?**

```kusto
Palo_FW_CL
| where Action == "allow"
| summarize count() by SrcIP
| top 10 by count_
```

**Example 2 · DNS: who asks the most questions?**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| summarize count() by ClientIP
| top 10 by count_
```

**Example 3 · NetScaler: which clients use the SSL VPN most?**

```kusto
Netscaler_Logs_CL
| where Module == "SSLVPN" and isnotempty(ClientIP)
| summarize count() by ClientIP
| top 10 by count_
```

#### 2.3 Query structure: table, pipe, filter, aggregate, order, project

*01-KQL.pptx · slide 44* — The common closing project renames and limits the columns.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| where TimeGenerated > ago(30d)
| where Action == "deny"
| summarize count() by SrcIP
| order by SrcIP asc
| project SrcIP, DeniedSessions = count_
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| where TimeGenerated > ago(30d)
| where EventType == "Query"
| summarize count() by ClientIP
| order by ClientIP asc
| project ClientIP, Queries = count_
```

**Example 3 · DHCP**

```kusto
Infoblox_DHCP_CL
| where TimeGenerated > ago(30d)
| summarize count() by EventType
| order by EventType asc
| project EventType, Events = count_
```

#### 2.4 Query development process

*01-KQL.pptx · slide 45* — Start with a question, find the table, explore, filter, shape, enrich, summarize.

**Example 1 · Question: which firewall rules block the most traffic?**

```kusto
// 1. Question and table
Palo_FW_CL
// 2. Filter away unnecessary rows
| where Action in ("deny", "reset-both", "block-url")
// 3. Filter away unnecessary columns
| project Rule, App, SrcIP
// 4. Summarize
| summarize Blocks = count() by Rule, App
| top 10 by Blocks
```

**Example 2 · Question: which names fail to resolve?**

```kusto
// 1. Question and table
Infoblox_DNS_CL
// 2. Filter rows
| where EventType == "QueryFailure"
// 3. Customize / enrich
| extend Domain = tostring(split(DnsQuery, ".")[-1])
// 4. Summarize and rename
| summarize Failures = count(), Clients = dcount(ClientIP) by DnsQuery, FailureReason
| sort by Failures desc
```

**Example 3 · Question: which DHCP clients renew the most?**

```kusto
// 1. Question and table
Infoblox_DHCP_CL
// 2. Filter rows
| where EventType == "DHCPREQUEST" and LeaseState == "RENEW"
// 3. Filter columns
| project ClientHostname, ClientMAC, LeaseIP
// 4. Summarize
| summarize Renewals = count() by ClientHostname, ClientMAC
| top 10 by Renewals
```

#### 2.5 Syntax rules: pipes, case sensitivity, comments, strings and numbers

*01-KQL.pptx · slide 46* — Pipe between stages, // for comments, quotes for strings, no quotes for numbers, semicolon only after let.

**Example 1 · Pipes, stacked lines and comments**

```kusto
// Firewall denies
Palo_FW_CL
| where Action == "deny"   // exact, case-sensitive match
| take 5
```

**Example 2 · Case sensitivity: == vs =~**

```kusto
Palo_FW_CL
| summarize CaseSensitive = countif(Action == "DENY"),
            CaseInsensitive = countif(Action =~ "DENY")
```

**Example 3 · Strings in quotes, numbers without, let ends with ;**

```kusto
let Port = 443;
let Blocked = "deny";
Palo_FW_CL
| where DestPort == Port and Action != Blocked
| take 5
```

#### 2.6 Discovery: search

*01-KQL.pptx · slide 47* — search looks for a keyword in every column. Scoped here to the four network tables.

**Example 1 · Keyword across all four tables**

```kusto
search in (Palo_FW_CL, Infoblox_DNS_CL, Infoblox_DHCP_CL, Netscaler_Logs_CL) "10.216.132.166"
```

**Example 2 · Which table holds the keyword?**

```kusto
search in (Palo_FW_CL, Infoblox_DNS_CL, Infoblox_DHCP_CL, Netscaler_Logs_CL) "10.216.132.166"
| summarize by $table
```

**Example 3 · Search inside one table**

```kusto
Palo_FW_CL
| search "teamviewer"
| take 10
```

#### 2.7 Discovery: count

*01-KQL.pptx · slide 47* — Total number of records.

**Example 1 · All firewall records**

```kusto
Palo_FW_CL
| count
```

**Example 2 · DHCP acknowledgements**

```kusto
Infoblox_DHCP_CL
| where EventType == "DHCPACK"
| count
```

**Example 3 · NetScaler TCP events**

```kusto
Netscaler_Logs_CL
| where Module == "TCP"
| count
```

#### 2.8 Discovery: print

*01-KQL.pptx · slide 47* — Verify a value or a function output; here the table is used to compute the value.

**Example 1 · Latest firewall event**

```kusto
print LatestFirewallEvent = toscalar(Palo_FW_CL | summarize max(TimeGenerated))
```

**Example 2 · A relative time and a record count**

```kusto
print Lookback = ago(1d), NetScalerRecords = toscalar(Netscaler_Logs_CL | count)
```

**Example 3 · Time span covered by DHCP**

```kusto
print FirstDhcpEvent = toscalar(Infoblox_DHCP_CL | summarize min(TimeGenerated)),
      LastDhcpEvent = toscalar(Infoblox_DHCP_CL | summarize max(TimeGenerated))
```

#### 2.9 Discovery: distinct

*01-KQL.pptx · slide 47* — Return the distinct values of a column.

**Example 1 · Firewall actions**

```kusto
Palo_FW_CL
| distinct Action
```

**Example 2 · DNS event and query types**

```kusto
Infoblox_DNS_CL
| distinct EventType, QueryType
```

**Example 3 · NetScaler modules and events**

```kusto
Netscaler_Logs_CL
| distinct Module, EventType
```

#### 2.10 Discovery: take

*01-KQL.pptx · slide 47* — Limit the number of results.

**Example 1 · Ten firewall rows**

```kusto
Palo_FW_CL
| take 10
```

**Example 2 · Five DNS queries**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| take 5
```

**Example 3 · limit is the same as take**

```kusto
Netscaler_Logs_CL
| limit 5
```

#### 2.11 Filtering with where: conditions can be concatenated

*01-KQL.pptx · slide 48* — One where with and, or several where lines: same result.

**Example 1 · Time only**

```kusto
Palo_FW_CL
| where TimeGenerated >= ago(30d)
```

**Example 2 · Time and a column in one where**

```kusto
Palo_FW_CL
| where TimeGenerated >= ago(30d) and Action == "deny"
```

**Example 3 · The same condition in two where lines**

```kusto
Palo_FW_CL
| where TimeGenerated >= ago(30d)
| where Action == "deny"
```

#### 2.12 where: start with filtering by time (relative times)

*01-KQL.pptx · slide 49* — ago() is relative to now. Units: s, m, h, d.

**Example 1 · Last day (static sample: returns data only while it is under a day old)**

```kusto
Palo_FW_CL
| where TimeGenerated > ago(1d)
```

**Example 2 · Last week**

```kusto
Infoblox_DNS_CL
| where TimeGenerated > ago(7d)
```

**Example 3 · Last 30 days**

```kusto
Infoblox_DHCP_CL
| where TimeGenerated > ago(30d)
```

#### 2.13 where: time filter and a condition combined with and

*01-KQL.pptx · slide 49* — Comment the intent next to the condition.

**Example 1 · Firewall: blocked traffic**

```kusto
Palo_FW_CL
| where TimeGenerated > ago(30d) and Action == "deny"   // blocked
```

**Example 2 · DNS: failed lookups**

```kusto
Infoblox_DNS_CL
| where TimeGenerated > ago(30d) and EventType == "QueryFailure"   // failure
```

**Example 3 · DHCP: acknowledged leases**

```kusto
Infoblox_DHCP_CL
| where TimeGenerated > ago(30d) and EventType == "DHCPACK"   // lease acknowledged
```

#### 2.14 where: chained filters and case-insensitive match (=~)

*01-KQL.pptx · slide 49* — Stack where lines; =~ ignores case.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| where TimeGenerated > ago(30d)
| where Protocol == "tcp"
| where Action =~ "DENY"   // case insensitive
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| where TimeGenerated > ago(30d)
| where EventType == "Query"
| where QueryType =~ "aaaa"   // case insensitive
```

**Example 3 · NetScaler**

```kusto
Netscaler_Logs_CL
| where TimeGenerated > ago(30d)
| where EventType == "HTTPREQUEST"
| where Module =~ "sslvpn"   // case insensitive
```

#### 2.15 where: lists with in (lists can be dynamic)

*01-KQL.pptx · slide 49* — in matches any value of a list.

**Example 1 · Firewall actions**

```kusto
Palo_FW_CL
| where Action in ("deny", "reset-both", "block-url")
```

**Example 2 · DNS event types**

```kusto
Infoblox_DNS_CL
| where EventType in ("Query", "QueryFailure")
```

**Example 3 · DHCP exchange events**

```kusto
Infoblox_DHCP_CL
| where EventType in ("DHCPDISCOVER", "DHCPOFFER", "DHCPREQUEST", "DHCPACK")
```

#### 2.16 where: additional built-in operator ipv4_is_match

*01-KQL.pptx · slide 49* — Subnet matching with CIDR notation.

**Example 1 · Firewall sources in 10.0.0.0/8**

```kusto
Palo_FW_CL
| where ipv4_is_match(SrcIP, "10.0.0.0/8")
```

**Example 2 · DNS clients in 10.216.0.0/16**

```kusto
Infoblox_DNS_CL
| where ipv4_is_match(ClientIP, "10.216.0.0/16")
```

**Example 3 · NetScaler clients in 10.0.0.0/8**

```kusto
Netscaler_Logs_CL
| where isnotempty(ClientIP)
| where ipv4_is_match(ClientIP, "10.0.0.0/8")
```

#### 2.17 where: matches regex

*01-KQL.pptx · slide 49* — Regular expressions for patterns a simple operator cannot express.

**Example 1 · Firewall rule names ending in a number**

```kusto
Palo_FW_CL
| where Rule matches regex "^AzureToInfoBlox-[0-9]+$"
```

**Example 2 · DNS names under microsoft.com with one label**

```kusto
Infoblox_DNS_CL
| where DnsQuery matches regex @"^[a-z0-9-]+\.microsoft\.com$"
```

**Example 3 · DHCP hostnames made of letters followed by digits**

```kusto
Infoblox_DHCP_CL
| where ClientHostname matches regex "^[A-Z]+[0-9]+[A-Z0-9]*$"
```

#### 2.18 project: choose the columns

*01-KQL.pptx · slide 50* — Only the listed columns are returned, in the order listed.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| project TimeGenerated, SrcIP, DestIP, DestPort, Action
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| project TimeGenerated, ClientIP, DnsQuery
```

**Example 3 · DHCP**

```kusto
Infoblox_DHCP_CL
| project TimeGenerated, LeaseIP, ClientMAC, ClientHostname
```

#### 2.19 project: rename columns

*01-KQL.pptx · slide 50* — Name = Column renames while projecting.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| project Time = TimeGenerated, Source = SrcIP, Destination = DestIP, Port = DestPort
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| project TIME = TimeGenerated, CLIENT = ClientIP, NAME = DnsQuery
```

**Example 3 · NetScaler**

```kusto
Netscaler_Logs_CL
| project Time = TimeGenerated, Appliance = DeviceName, Client = ClientIP, EventName = EventType
```

#### 2.20 project examples: a calculated column with iff

*01-KQL.pptx · slide 51* — An 'if' function similar to Excel's.

**Example 1 · Firewall: is it blocked?**

```kusto
Palo_FW_CL
| project TimeGenerated, SrcIP, IsBlocked = iff(Action in ("deny", "reset-both", "block-url"), true, false)
```

**Example 2 · DNS: is it a Microsoft name?**

```kusto
Infoblox_DNS_CL
| project ClientIP, DnsQuery, IsMicrosoft = iff(DnsQuery contains "microsoft", true, false)
```

**Example 3 · DHCP: does the hostname follow the WP naming?**

```kusto
Infoblox_DHCP_CL
| where isnotempty(ClientHostname)
| project LeaseIP, ClientHostname, IsWorkstation = iff(ClientHostname startswith "WP", true, false)
```

#### 2.21 project examples: where, then project

*01-KQL.pptx · slide 51* — Filter first, then keep the columns you need.

**Example 1 · Firewall DNS traffic**

```kusto
Palo_FW_CL
| where DestPort == 53
| project SrcIP, DestIP, App
```

**Example 2 · DNS A-record queries**

```kusto
Infoblox_DNS_CL
| where QueryType == "A"
| project ClientIP, DnsQuery
```

**Example 3 · NetScaler TCP events**

```kusto
Netscaler_Logs_CL
| where Module == "TCP"
| project DeviceName, EventType, SrcIP, DstIP
```

#### 2.22 extend: build a string with strcat

*01-KQL.pptx · slide 52* — extend creates new columns (enrichment, concatenation, parsing).

**Example 1 · Firewall flow**

```kusto
Palo_FW_CL
| extend Flow = strcat(SrcIP, " -> ", DestIP)
| project TimeGenerated, Flow, Action
```

**Example 2 · DNS lookup sentence**

```kusto
Infoblox_DNS_CL
| extend Lookup = strcat(ClientIP, " asked for ", DnsQuery)
| project TimeGenerated, Lookup
```

**Example 3 · NetScaler appliance and module**

```kusto
Netscaler_Logs_CL
| extend Source = strcat(DeviceName, " / ", Module)
| project TimeGenerated, Source, EventType
```

#### 2.23 extend: calculated columns

*01-KQL.pptx · slide 52* — Arithmetic on numeric columns.

**Example 1 · Firewall total bytes**

```kusto
Palo_FW_CL
| extend TotalBytes = BytesIn + BytesOut
| project TimeGenerated, SrcIP, DestIP, TotalBytes
```

**Example 2 · Firewall bytes in megabytes**

```kusto
Palo_FW_CL
| extend OutMB = round(BytesOut / 1000000.0, 2)
| project TimeGenerated, SrcIP, DestIP, OutMB
```

**Example 3 · NetScaler total bytes**

```kusto
Netscaler_Logs_CL
| where isnotnull(BytesSent)
| extend TotalBytes = BytesSent + BytesReceived
| project TimeGenerated, ClientIP, TotalBytes
```

#### 2.24 extend examples: arithmetic columns (FreeKB / FreeGB style)

*01-KQL.pptx · slide 53* — Several extend lines build on each other.

**Example 1 · Firewall: KB and MB**

```kusto
Palo_FW_CL
| where isnotnull(BytesOut)
| extend OutKB = BytesOut / 1000
| extend OutMB = OutKB / 1000
| project TimeGenerated, SrcIP, OutKB, OutMB
```

**Example 2 · NetScaler: KB received**

```kusto
Netscaler_Logs_CL
| where isnotnull(BytesReceived)
| extend ReceivedKB = BytesReceived / 1000
| project TimeGenerated, ClientIP, ReceivedKB
```

**Example 3 · Firewall: bytes ratio**

```kusto
Palo_FW_CL
| where BytesIn > 0
| extend OutToInRatio = round(todouble(BytesOut) / BytesIn, 2)
| project TimeGenerated, SrcIP, DestIP, OutToInRatio
```

#### 2.25 extend examples: extract a value

*01-KQL.pptx · slide 53* — extract(regex, group, text) pulls a value out of a string.

**Example 1 · NetScaler error number**

```kusto
Netscaler_Logs_CL
| where Payload has "errno"
| extend ErrNo = extract("errno: ([0-9]+)", 1, Payload)
| project TimeGenerated, ErrNo
```

**Example 2 · DNS first label**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| extend FirstLabel = extract("^([a-z0-9-]+)\\.", 1, DnsQuery)
| project ClientIP, DnsQuery, FirstLabel
```

**Example 3 · Firewall: first two octets**

```kusto
Palo_FW_CL
| extend Network = extract("^([0-9]+\\.[0-9]+)\\.", 1, SrcIP)
| summarize Sessions = count() by Network
```

#### 2.26 extend examples: split

*01-KQL.pptx · slide 53* — split breaks a delimited value into an array.

**Example 1 · Firewall: first octet**

```kusto
Palo_FW_CL
| extend FirstOctet = tostring(split(SrcIP, ".")[0])
| summarize Sessions = count() by FirstOctet
```

**Example 2 · DNS: first and last label**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| extend Labels = split(DnsQuery, ".")
| extend First = tostring(Labels[0]), Last = tostring(Labels[-1])
| project DnsQuery, First, Last
```

**Example 3 · DHCP: parts of a dhcp-a-b-c-d hostname**

```kusto
Infoblox_DHCP_CL
| where ClientHostname startswith "dhcp-"
| extend Parts = split(ClientHostname, "-")
| project ClientHostname, ThirdOctet = tostring(Parts[3]), FourthOctet = tostring(Parts[4])
```

#### 2.27 extend examples: parse

*01-KQL.pptx · slide 53* — parse extracts values between fixed text.

**Example 1 · NetScaler: session start**

```kusto
Netscaler_Logs_CL
| where isnotempty(SessionStart)
| parse SessionStart with Month "/" Day "/" Year ":" Clock " GMT"
| project SessionStart, Year, Month, Day, Clock
```

**Example 2 · DHCP: octets of a dhcp- hostname**

```kusto
Infoblox_DHCP_CL
| where ClientHostname startswith "dhcp-"
| parse ClientHostname with "dhcp-" A "-" B "-" C "-" D
| project ClientHostname, A, B, C, D
```

**Example 3 · NetScaler: error and key**

```kusto
Netscaler_Logs_CL
| where Payload has "errno"
| parse Payload with * "errno: " ErrNo " key: " Key
| project TimeGenerated, ErrNo, Key
```

#### 2.28 summarize: count records per entity

*01-KQL.pptx · slide 54* — Group results and count.

**Example 1 · Firewall: sessions per source**

```kusto
Palo_FW_CL
| summarize count() by SrcIP
```

**Example 2 · DNS: queries per name**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| summarize count() by DnsQuery
```

**Example 3 · NetScaler: events per appliance**

```kusto
Netscaler_Logs_CL
| summarize count() by DeviceName
```

#### 2.29 summarize: group by several columns

*01-KQL.pptx · slide 54* — The output has one row per distinct combination.

**Example 1 · Firewall: action and protocol**

```kusto
Palo_FW_CL
| summarize count() by Action, Protocol
```

**Example 2 · DNS: event type and query type**

```kusto
Infoblox_DNS_CL
| summarize count() by EventType, QueryType
```

**Example 3 · NetScaler: module and event type**

```kusto
Netscaler_Logs_CL
| summarize count() by Module, EventType
```

#### 2.30 summarize with bin(): time series

*01-KQL.pptx · slide 54* — Used with bin() to present time-series charts.

**Example 1 · Firewall: events per 10 seconds**

```kusto
Palo_FW_CL
| summarize count() by bin(TimeGenerated, 10s)
| sort by TimeGenerated asc
```

**Example 2 · DHCP: events per minute**

```kusto
Infoblox_DHCP_CL
| summarize count() by bin(TimeGenerated, 1m)
| sort by TimeGenerated asc
```

**Example 3 · NetScaler: events per minute**

```kusto
Netscaler_Logs_CL
| summarize count() by bin(TimeGenerated, 1m)
| sort by TimeGenerated asc
```

#### 2.31 summarize with arg_max(): latest record per entity (health state)

*01-KQL.pptx · slide 54* — arg_max(TimeGenerated, *) returns the whole latest row per group.

**Example 1 · Firewall: last session per source**

```kusto
Palo_FW_CL
| summarize arg_max(TimeGenerated, *) by SrcIP
| project TimeGenerated, SrcIP, DestIP, Action
```

**Example 2 · DHCP: last event per leased IP**

```kusto
Infoblox_DHCP_CL
| summarize arg_max(TimeGenerated, *) by LeaseIP
| project TimeGenerated, LeaseIP, EventType, ClientHostname
```

**Example 3 · NetScaler: last event type per appliance**

```kusto
Netscaler_Logs_CL
| summarize arg_max(TimeGenerated, EventType) by DeviceName
```

#### 2.32 summarize with sort by

*01-KQL.pptx · slide 54* — Sort by sets the order of the aggregated result.

**Example 1 · Firewall: busiest sources**

```kusto
Palo_FW_CL
| summarize Sessions = count() by SrcIP
| sort by Sessions desc
```

**Example 2 · DNS: most-asked names**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| summarize Queries = count() by DnsQuery
| sort by Queries desc
```

**Example 3 · NetScaler: appliances by event count**

```kusto
Netscaler_Logs_CL
| summarize Events = count() by DeviceName
| sort by Events desc
```

#### 2.33 summarize examples: min() with a filter

*01-KQL.pptx · slide 55* — Minimum of a numeric column or a time.

**Example 1 · Firewall: smallest allowed session**

```kusto
Palo_FW_CL
| where Action == "allow"
| summarize min(BytesOut)
```

**Example 2 · DHCP: earliest event**

```kusto
Infoblox_DHCP_CL
| summarize min(TimeGenerated)
```

**Example 3 · DNS: shortest queried name**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| summarize min(strlen(DnsQuery))
```

#### 2.34 summarize examples: count by two columns (logins by user and computer style)

*01-KQL.pptx · slide 55* — Count by a pair of columns.

**Example 1 · Firewall: source zone and destination zone**

```kusto
Palo_FW_CL
| where TimeGenerated > ago(30d)
| summarize count() by SrcZone, DestZone
```

**Example 2 · DNS: client and query type**

```kusto
Infoblox_DNS_CL
| where TimeGenerated > ago(30d)
| where EventType == "Query"
| summarize count() by ClientIP, QueryType
```

**Example 3 · NetScaler: client and module**

```kusto
Netscaler_Logs_CL
| where TimeGenerated > ago(30d) and isnotempty(ClientIP)
| summarize count() by ClientIP, Module
```

#### 2.35 summarize examples: dcount() returns a single value

*01-KQL.pptx · slide 55* — Count distinct values of the selected data set.

**Example 1 · Firewall: distinct sources with allowed traffic**

```kusto
Palo_FW_CL
| where Action == "allow"
| summarize dcount(SrcIP)
```

**Example 2 · DNS: distinct clients**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| summarize dcount(ClientIP)
```

**Example 3 · NetScaler: distinct clients**

```kusto
Netscaler_Logs_CL
| where isnotempty(ClientIP)
| summarize dcount(ClientIP)
```

#### 2.36 summarize examples: the default column name (count_) and how to override it

*01-KQL.pptx · slide 55* — Use c = count() to name the column.

**Example 1 · Default name: count_**

```kusto
Palo_FW_CL
| summarize count() by Action
```

**Example 2 · Override with c**

```kusto
Palo_FW_CL
| summarize c = count() by Action
```

**Example 3 · A meaningful name**

```kusto
Infoblox_DHCP_CL
| summarize Events = count() by EventType
```

#### 2.37 render timechart (with a title)

*01-KQL.pptx · slide 56* — render must be the last operator.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| summarize count() by bin(TimeGenerated, 5s)
| render timechart with (title = "Firewall events per 5 seconds")
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| summarize count() by bin(TimeGenerated, 1s)
| render timechart with (title = "DNS events per second")
```

**Example 3 · NetScaler**

```kusto
Netscaler_Logs_CL
| summarize count() by bin(TimeGenerated, 1m)
| render timechart with (title = "NetScaler events per minute")
```

#### 2.38 render piechart

*01-KQL.pptx · slide 56* — Share of a whole across a category.

**Example 1 · Firewall actions**

```kusto
Palo_FW_CL
| summarize count() by Action
| render piechart
```

**Example 2 · DNS query types**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| summarize count() by QueryType
| render piechart
```

**Example 3 · NetScaler modules**

```kusto
Netscaler_Logs_CL
| summarize count() by Module
| render piechart
```

#### 2.39 Useful functions: ago()

*01-KQL.pptx · slide 57* — ago() is the primary date-time selector.

**Example 1 · Firewall: last 30 days**

```kusto
Palo_FW_CL
| where TimeGenerated >= ago(30d)
```

**Example 2 · DNS: last 7 days**

```kusto
Infoblox_DNS_CL
| where TimeGenerated >= ago(7d)
```

**Example 3 · DHCP: older than an hour**

```kusto
Infoblox_DHCP_CL
| where TimeGenerated < ago(1h)
```

#### 2.40 Useful functions: iff() / iif()

*01-KQL.pptx · slide 57* — Classic if / then / else.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| extend Level2 = iff(Action in ("deny", "reset-both", "block-url"), "DANGER", "WARNING")
| summarize count() by Level2
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| extend Level2 = iff(EventType == "QueryFailure", "DANGER", "WARNING")
| summarize count() by Level2
```

**Example 3 · DHCP**

```kusto
Infoblox_DHCP_CL
| extend Level2 = iff(EventType == "AbandonedLease", "DANGER", "WARNING")
| summarize count() by Level2
```

#### 2.41 Useful functions: case()

*01-KQL.pptx · slide 57* — Like iff() with more branches.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| extend Level2 = case(Action == "allow", "INFO", Action == "alert", "WARNING", Action in ("deny", "reset-both", "block-url"), "DANGER", "UNKNOWN")
| summarize count() by Level2
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| extend Level2 = case(EventType == "Query", "INFO", EventType == "QueryFailure", "DANGER", "UNKNOWN")
| summarize count() by Level2
```

**Example 3 · DHCP**

```kusto
Infoblox_DHCP_CL
| extend Level2 = case(EventType == "DHCPACK", "INFO", EventType == "AbandonedLease", "DANGER", "UNKNOWN")
| summarize count() by Level2
```

#### 2.42 Useful functions: parse_url()

*01-KQL.pptx · slide 57* — Breaks a URL into its parts. The URL is built with strcat because the sample columns hold host and path separately.

**Example 1 · Firewall destination**

```kusto
Palo_FW_CL
| where isnotempty(DestPort)
| extend U = parse_url(strcat("https://", DestIP, ":", DestPort, "/"))
| project DestIP, Host = tostring(U.Host), Port = tostring(U.Port)
| take 10
```

**Example 2 · NetScaler request**

```kusto
Netscaler_Logs_CL
| where isnotempty(HttpUrl)
| extend U = parse_url(strcat("https://", RequestHost, HttpUrl))
| project RequestHost, Path = tostring(U.Path)
| take 10
```

**Example 3 · DNS name**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| extend U = parse_url(strcat("https://", DnsQuery, "/"))
| project DnsQuery, Host = tostring(U.Host)
| take 10
```

#### 2.43 Useful functions: split()

*01-KQL.pptx · slide 57* — Breaks a delimited value into an array.

**Example 1 · DNS name labels**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| extend Labels = split(DnsQuery, ".")
| project DnsQuery, Labels
| take 10
```

**Example 2 · Firewall source octets**

```kusto
Palo_FW_CL
| extend Octets = split(SrcIP, ".")
| project SrcIP, Octets
| take 10
```

**Example 3 · DHCP MAC address bytes**

```kusto
Infoblox_DHCP_CL
| where isnotempty(ClientMAC)
| extend Bytes = split(ClientMAC, ":")
| project ClientMAC, Vendor = strcat(Bytes[0], Bytes[1], Bytes[2])
| take 10
```

#### 2.44 Useful functions: strcat()

*01-KQL.pptx · slide 57* — Combines values into a single string.

**Example 1 · Firewall endpoint**

```kusto
Palo_FW_CL
| where isnotempty(DestPort)
| extend Endpoint = strcat(DestIP, ":", DestPort)
| project TimeGenerated, Endpoint, App
```

**Example 2 · DNS client and name**

```kusto
Infoblox_DNS_CL
| extend Pair = strcat(ClientIP, "|", DnsQuery)
| project TimeGenerated, Pair
```

**Example 3 · DHCP device label**

```kusto
Infoblox_DHCP_CL
| where isnotempty(ClientHostname)
| extend Device = strcat(ClientHostname, " (", ClientMAC, ")")
| project TimeGenerated, Device, LeaseIP
```

#### 2.45 Useful functions: parse

*01-KQL.pptx · slide 57* — Extracts a value from a string.

**Example 1 · NetScaler error and key**

```kusto
Netscaler_Logs_CL
| where Payload has "errno"
| parse Payload with * "errno: " ErrNo " key: " Key
| project TimeGenerated, ErrNo, Key
```

**Example 2 · NetScaler session date**

```kusto
Netscaler_Logs_CL
| where isnotempty(SessionEnd)
| parse SessionEnd with Month "/" Day "/" Year ":" Clock " GMT"
| project SessionEnd, Year, Month, Day, Clock
```

**Example 3 · DHCP hostname**

```kusto
Infoblox_DHCP_CL
| where ClientHostname startswith "dhcp-"
| parse ClientHostname with "dhcp-" A "-" B "-" C "-" D
| project ClientHostname, A, B, C, D
```

#### 2.46 Useful functions: series_decompose_anomalies() (anomaly detection against a baseline)

*01-KQL.pptx · slide 57* — Build a time series with make-series, then flag points that deviate. The lab data spans seconds or minutes, so the step is small.

**Example 1 · DNS: queries per second**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| make-series Queries = count() on TimeGenerated step 1s
| extend (Spike, Score, Baseline) = series_decompose_anomalies(Queries, 1.5)
| mv-expand TimeGenerated to typeof(datetime), Queries to typeof(long), Spike to typeof(int)
| where Spike != 0
```

**Example 2 · Firewall: sessions per second**

```kusto
Palo_FW_CL
| make-series Sessions = count() on TimeGenerated step 1s
| extend (Spike, Score, Baseline) = series_decompose_anomalies(Sessions, 1.5)
| mv-expand TimeGenerated to typeof(datetime), Sessions to typeof(long), Spike to typeof(int)
| project TimeGenerated, Sessions, Spike
```

**Example 3 · NetScaler: events per 5 seconds**

```kusto
Netscaler_Logs_CL
| make-series Events = count() on TimeGenerated step 5s
| extend (Spike, Score, Baseline) = series_decompose_anomalies(Events, 1.5)
| mv-expand TimeGenerated to typeof(datetime), Events to typeof(long), Spike to typeof(int)
| project TimeGenerated, Events, Spike
```

#### 2.47 let: a single value

*01-KQL.pptx · slide 58* — A temporary variable before a complex query.

**Example 1 · Port**

```kusto
let Port = 443;
Palo_FW_CL
| where DestPort == Port
```

**Example 2 · Byte threshold**

```kusto
let MinBytes = 1000000;
Palo_FW_CL
| where BytesOut > MinBytes
```

**Example 3 · DNS server**

```kusto
let Server = "10.158.8.10";
Infoblox_DNS_CL
| where DNSServerIP == Server
```

#### 2.48 let: a list (allow, deny and exclusion lists)

*01-KQL.pptx · slide 58* — Use dynamic arrays with in.

**Example 1 · Blocked actions**

```kusto
let BlockedActions = dynamic(["deny", "reset-both", "block-url"]);
Palo_FW_CL
| where Action in (BlockedActions)
```

**Example 2 · Domains of interest**

```kusto
let Domains = dynamic(["microsoft.com", "azure.com"]);
Infoblox_DNS_CL
| where DnsQuery has_any (Domains)
```

**Example 3 · IP list**

```kusto
let IPList = dynamic(["10.216.132.166", "10.21.1.142", "10.192.132.14"]);
Infoblox_DHCP_CL
| where LeaseIP in (IPList)
```

#### 2.49 let: a temporary container for a table

*01-KQL.pptx · slide 58* — Name a sub-result and reuse it.

**Example 1 · Firewall top talkers**

```kusto
let TopTalkers = Palo_FW_CL
    | summarize Sessions = count() by SrcIP
    | top 5 by Sessions;
Palo_FW_CL
| where SrcIP in (TopTalkers | project SrcIP)
| summarize count() by SrcIP, Action
```

**Example 2 · DNS busiest clients**

```kusto
let BusyClients = Infoblox_DNS_CL
    | where EventType == "Query"
    | summarize Queries = count() by ClientIP
    | top 5 by Queries;
Infoblox_DNS_CL
| where ClientIP in (BusyClients | project ClientIP)
| summarize count() by ClientIP, QueryType
```

**Example 3 · DHCP chattiest hosts**

```kusto
let ChattyHosts = Infoblox_DHCP_CL
    | where isnotempty(ClientHostname)
    | summarize Events = count() by ClientHostname
    | top 3 by Events;
Infoblox_DHCP_CL
| where ClientHostname in (ChattyHosts | project ClientHostname)
| summarize count() by ClientHostname, EventType
```

#### 2.50 let examples: a table 'view' that is the result of a query

*01-KQL.pptx · slide 59* — Note the semicolon at the end of the let statement.

**Example 1 · Firewall sources with little activity**

```kusto
let LowActivitySources = Palo_FW_CL
    | summarize cnt = count() by SrcIP
    | where cnt < 5;
LowActivitySources
| where SrcIP startswith "10.238."
```

**Example 2 · DNS clients with little activity**

```kusto
let LowActivityClients = Infoblox_DNS_CL
    | summarize cnt = count() by ClientIP
    | where cnt < 3;
LowActivityClients
| where ClientIP startswith "10.216."
```

**Example 3 · NetScaler clients with little activity**

```kusto
let LowActivityClients = Netscaler_Logs_CL
    | where isnotempty(ClientIP)
    | summarize cnt = count() by ClientIP
    | where cnt < 3;
LowActivityClients
| where ClientIP startswith "10."
```

#### 2.51 let examples: time offset and a value to discard

*01-KQL.pptx · slide 59* — Variables keep the query readable.

**Example 1 · Firewall**

```kusto
let timeOffset = 30d;
let discardApp = "dns-base";
Palo_FW_CL
| where TimeGenerated > ago(timeOffset)
| where App != discardApp
```

**Example 2 · DNS**

```kusto
let timeOffset = 30d;
let discardType = "AAAA";
Infoblox_DNS_CL
| where TimeGenerated > ago(timeOffset)
| where QueryType != discardType
```

**Example 3 · NetScaler**

```kusto
let timeOffset = 30d;
let discardModule = "TCP";
Netscaler_Logs_CL
| where TimeGenerated > ago(timeOffset)
| where Module != discardModule
```

#### 2.52 let examples: a static table with datatable used as a list

*01-KQL.pptx · slide 59* — A one-column table can be used as a list.

**Example 1 · Firewall: applications to watch**

```kusto
let suspiciousApps = datatable(app: string) ["teamviewer-base", "quic-base"];
Palo_FW_CL
| where App in (suspiciousApps)
```

**Example 2 · DNS: names to watch**

```kusto
let watchNames = datatable(name: string) ["ingest.us1.signalfx.com", "login.microsoftonline.com"];
Infoblox_DNS_CL
| where DnsQuery in (watchNames)
```

**Example 3 · DHCP: devices to watch**

```kusto
let watchMacs = datatable(mac: string) ["5c:b2:6d:59:e1:f6", "38:ca:84:58:48:79"];
Infoblox_DHCP_CL
| where ClientMAC in (watchMacs)
```

#### 2.53 union: stack tables

*01-KQL.pptx · slide 60* — Union merges tables; results are stacked, with no comparison between values.

**Example 1 · All four tables with the source name**

```kusto
union withsource = SourceTable Palo_FW_CL, Infoblox_DNS_CL, Infoblox_DHCP_CL, Netscaler_Logs_CL
| summarize Records = count() by SourceTable
```

**Example 2 · Two filtered tables with a common column**

```kusto
union (Palo_FW_CL | where Action == "deny" | project TimeGenerated, Client = SrcIP),
      (Infoblox_DNS_CL | where EventType == "QueryFailure" | project TimeGenerated, Client = ClientIP)
| summarize Events = count() by Client
| top 10 by Events
```

**Example 3 · Wildcard on a table prefix**

```kusto
union withsource = SourceTable Infoblox_*
| summarize Records = count() by SourceTable
```

#### 2.54 join: compare two tables on a matching column

*01-KQL.pptx · slide 60* — join compares two tables and returns the matches.

**Example 1 · Firewall sources that also queried DNS**

```kusto
Palo_FW_CL
| take 1000
| join kind = innerunique (Infoblox_DNS_CL) on $left.SrcIP == $right.ClientIP
| project SrcIP, DestIP, DestPort, DnsQuery
| take 20
```

**Example 2 · DHCP hostname for each DNS client**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| join kind = inner (Infoblox_DHCP_CL | where isnotempty(ClientHostname) | summarize Hostname = any(ClientHostname) by LeaseIP) on $left.ClientIP == $right.LeaseIP
| project ClientIP, Hostname, DnsQuery
| take 20
```

**Example 3 · NetScaler clients enriched with the DHCP hostname**

```kusto
Netscaler_Logs_CL
| where isnotempty(ClientIP)
| join kind = leftouter (Infoblox_DHCP_CL | where isnotempty(ClientHostname) | summarize Hostname = any(ClientHostname) by LeaseIP) on $left.ClientIP == $right.LeaseIP
| project TimeGenerated, ClientIP, Hostname, Module, EventType
| take 20
```

#### 2.55 Cross-workspace queries: workspace()

*01-KQL.pptx · slide 61* — Reference another (or the same) workspace by name, ID or full resource path. These point at the workspace that holds the four tables.

**Example 1 · By workspace name**

```kusto
workspace("MSLearn-Sentinel").Palo_FW_CL
| count
```

**Example 2 · By workspace ID**

```kusto
workspace("53103aa6-bc3f-441c-9f6b-61a68c3a3570").Infoblox_DNS_CL
| summarize count() by EventType
```

**Example 3 · By fully qualified resource path**

```kusto
workspace("/subscriptions/616d9435-845f-4701-ba0c-a6e8709c89a3/resourcegroups/azure-sentinel-LEARN/providers/Microsoft.OperationalInsights/workspaces/MSLearn-Sentinel").Netscaler_Logs_CL
| count
```

#### 2.56 External data: lookup data that is not in a table (externaldata stand-in)

*01-KQL.pptx · slide 61* — externaldata reads a CSV from blob storage, which is outside the four tables. These examples use datatable, the inline equivalent, so they stay on your tables. adx() (query an Azure Data Explorer cluster) is not applicable here.

**Example 1 · Zone to owner lookup joined to the firewall**

```kusto
let ZoneOwners = datatable(Zone: string, Owner: string) ["private-zone", "Network", "external", "Internet edge", "transit-zone", "Transit"];
Palo_FW_CL
| join kind = inner (ZoneOwners) on $left.DestZone == $right.Zone
| summarize Sessions = count() by Owner
```

**Example 2 · Server role lookup joined to DNS**

```kusto
let DnsServers = datatable(ServerIP: string, Role: string) ["10.1.132.14", "Primary", "10.192.132.14", "Secondary"];
Infoblox_DNS_CL
| join kind = inner (DnsServers) on $left.DNSServerIP == $right.ServerIP
| summarize Events = count() by Role
```

**Example 3 · Appliance site lookup joined to NetScaler**

```kusto
let Sites = datatable(Appliance: string, Site: string) ["cat2yc3netscaler02", "Site A", "cat2yc1netscaler02", "Site B"];
Netscaler_Logs_CL
| join kind = inner (Sites) on $left.DeviceName == $right.Appliance
| summarize Events = count() by Site
```

#### 2.57 Most used commands: end-to-end examples

*01-KQL.pptx · slide 62* — where, project, extend, summarize, take, let, ago, render, join, iff and split in one query.

**Example 1 · Blocked firewall traffic by rule**

```kusto
Palo_FW_CL
| where TimeGenerated > ago(30d)
| where Action in ("deny", "reset-both", "block-url")
| extend Direction = iff(ipv4_is_private(DestIP), "Internal", "External")
| summarize Blocks = count() by Rule, Direction
| top 10 by Blocks
```

**Example 2 · DNS by top-level domain**

```kusto
Infoblox_DNS_CL
| where TimeGenerated > ago(30d) and EventType == "Query"
| extend Tld = tostring(split(DnsQuery, ".")[-1])
| summarize Queries = count() by Tld
| top 5 by Queries
| render piechart
```

**Example 3 · DHCP and DNS correlated for one client**

```kusto
let Client = "10.216.132.166";
Infoblox_DNS_CL
| where ClientIP == Client
| join kind = leftouter (Infoblox_DHCP_CL | where LeaseIP == Client and isnotempty(ClientHostname) | summarize Hostname = any(ClientHostname) by LeaseIP) on $left.ClientIP == $right.LeaseIP
| project TimeGenerated, ClientIP, Hostname, DnsQuery
```

#### 2.58 Filter: == (best performance)

*01-KQL.pptx · slide 63* — Equality is the best operator.

**Example 1 · Firewall action**

```kusto
Palo_FW_CL
| where Action == "deny"
| count
```

**Example 2 · DNS query type**

```kusto
Infoblox_DNS_CL
| where QueryType == "AAAA"
| count
```

**Example 3 · NetScaler module**

```kusto
Netscaler_Logs_CL
| where Module == "SSLVPN"
| count
```

#### 2.59 Filter: has

*01-KQL.pptx · slide 63* — Prefer has or startswith; case does not matter.

**Example 1 · Firewall rule**

```kusto
Palo_FW_CL
| where Rule has "AzureToInfoBlox"
| count
```

**Example 2 · DNS name**

```kusto
Infoblox_DNS_CL
| where DnsQuery has "microsoft"
| count
```

**Example 3 · NetScaler payload**

```kusto
Netscaler_Logs_CL
| where Payload has "errno"
| count
```

#### 2.60 Filter: has_cs

*01-KQL.pptx · slide 63* — Case-sensitive version of has.

**Example 1 · Firewall rule**

```kusto
Palo_FW_CL
| where Rule has_cs "AzureToInfoBlox"
| count
```

**Example 2 · DNS name**

```kusto
Infoblox_DNS_CL
| where DnsQuery has_cs "microsoft"
| count
```

**Example 3 · DHCP hostname**

```kusto
Infoblox_DHCP_CL
| where ClientHostname has_cs "MXL2262SL6"
| count
```

#### 2.61 Filter: startswith

*01-KQL.pptx · slide 63* — Prefix match.

**Example 1 · Firewall rule**

```kusto
Palo_FW_CL
| where Rule startswith "Azure"
| count
```

**Example 2 · DNS name**

```kusto
Infoblox_DNS_CL
| where DnsQuery startswith "login."
| count
```

**Example 3 · DHCP hostname**

```kusto
Infoblox_DHCP_CL
| where ClientHostname startswith "WP"
| count
```

#### 2.62 Filter: contains (avoid unless needed)

*01-KQL.pptx · slide 63* — Substring anywhere; slower than has.

**Example 1 · Firewall rule**

```kusto
Palo_FW_CL
| where Rule contains "Infoblox"
| count
```

**Example 2 · DNS name**

```kusto
Infoblox_DNS_CL
| where DnsQuery contains "microsoft"
| count
```

**Example 3 · NetScaler payload**

```kusto
Netscaler_Logs_CL
| where Payload contains "nFactor"
| count
```

#### 2.63 Filter: contains_cs

*01-KQL.pptx · slide 63* — Case-sensitive substring.

**Example 1 · Firewall rule**

```kusto
Palo_FW_CL
| where Rule contains_cs "InfoBlox"
| count
```

**Example 2 · DNS name**

```kusto
Infoblox_DNS_CL
| where DnsQuery contains_cs "microsoft"
| count
```

**Example 3 · DHCP hostname**

```kusto
Infoblox_DHCP_CL
| where ClientHostname contains_cs "MXL"
| count
```

#### 2.64 Filter: endswith (avoid unless needed)

*01-KQL.pptx · slide 63* — Suffix match.

**Example 1 · Firewall rule**

```kusto
Palo_FW_CL
| where Rule endswith "-2"
| count
```

**Example 2 · DNS name**

```kusto
Infoblox_DNS_CL
| where DnsQuery endswith ".microsoft.com"
| count
```

**Example 3 · DHCP hostname**

```kusto
Infoblox_DHCP_CL
| where ClientHostname endswith "SL6"
| count
```

#### 2.65 Filter: matches regex (simple pattern)

*01-KQL.pptx · slide 63* — A simple regular expression behaves like contains.

**Example 1 · Firewall rule**

```kusto
Palo_FW_CL
| where Rule matches regex "Infoblox"
| count
```

**Example 2 · DNS name**

```kusto
Infoblox_DNS_CL
| where DnsQuery matches regex "microsoft"
| count
```

**Example 3 · NetScaler payload**

```kusto
Netscaler_Logs_CL
| where Payload matches regex "errno"
| count
```

#### 2.66 Filter: matches regex (digit pattern)

*01-KQL.pptx · slide 63* — More complex patterns cost more.

**Example 1 · Firewall rule digits**

```kusto
Palo_FW_CL
| where Rule matches regex "[0-9]{1,2}$"
| count
```

**Example 2 · DNS name with a long number**

```kusto
Infoblox_DNS_CL
| where DnsQuery matches regex "[0-9]{8,9}"
| count
```

**Example 3 · NetScaler key digits**

```kusto
Netscaler_Logs_CL
| where Payload matches regex "key: [0-9]{6,7}"
| count
```

#### 2.67 Filter: search (multi-field matching is expensive)

*01-KQL.pptx · slide 63* — search looks in every column; scoped here to one table.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| search "teamviewer"
| count
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| search "signalfx"
| count
```

**Example 3 · NetScaler**

```kusto
Netscaler_Logs_CL
| search "nFactor"
| count
```

#### 2.68 Filter: * has (multi-field matching)

*01-KQL.pptx · slide 63* — Same cost profile as search.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| where * has "teamviewer"
| count
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| where * has "signalfx"
| count
```

**Example 3 · DHCP**

```kusto
Infoblox_DHCP_CL
| where * has "DHCPACK"
| count
```

#### 2.69 SQL vs KQL: select all data from a table

*01-KQL.pptx · slide 64* — SQL: `SELECT * FROM Palo_FW_CL`

**Example 1 · Firewall**

```kusto
Palo_FW_CL
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
```

**Example 3 · DHCP**

```kusto
Infoblox_DHCP_CL
```

#### 2.70 SQL vs KQL: select specific columns

*01-KQL.pptx · slide 64* — SQL: `SELECT SrcIP, DestIP FROM Palo_FW_CL`

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| project SrcIP, DestIP
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| project ClientIP, DnsQuery
```

**Example 3 · NetScaler**

```kusto
Netscaler_Logs_CL
| project DeviceName, Module, EventType
```

#### 2.71 SQL vs KQL: select 100 records (TOP 100)

*01-KQL.pptx · slide 64* — SQL: `SELECT TOP 100 * FROM Palo_FW_CL`

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| take 100
```

**Example 2 · DHCP**

```kusto
Infoblox_DHCP_CL
| take 100
```

**Example 3 · NetScaler**

```kusto
Netscaler_Logs_CL
| take 100
```

#### 2.72 SQL vs KQL: null evaluation

*01-KQL.pptx · slide 64* — SQL: `SELECT * FROM Palo_FW_CL WHERE BytesOut IS NOT NULL`

**Example 1 · Firewall: numeric column**

```kusto
Palo_FW_CL
| where isnotnull(BytesOut)
```

**Example 2 · DHCP: text column (empty string)**

```kusto
Infoblox_DHCP_CL
| where isnotempty(ClientHostname)
```

**Example 3 · NetScaler: numeric column**

```kusto
Netscaler_Logs_CL
| where isnotnull(BytesSent)
```

#### 2.73 SQL vs KQL: string equality

*01-KQL.pptx · slide 64* — SQL: `SELECT * FROM Palo_FW_CL WHERE Action = 'deny'`

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| where Action == "deny"
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| where EventType == "QueryFailure"
```

**Example 3 · DHCP**

```kusto
Infoblox_DHCP_CL
| where EventType == "DHCPACK"
```

#### 2.74 SQL vs KQL: string substring (LIKE '%abc%')

*01-KQL.pptx · slide 64* — SQL: `SELECT * FROM Infoblox_DNS_CL WHERE DnsQuery LIKE '%microsoft%'`

**Example 1 · DNS**

```kusto
Infoblox_DNS_CL
| where DnsQuery contains "microsoft"
```

**Example 2 · Firewall**

```kusto
Palo_FW_CL
| where Rule contains "Infoblox"
```

**Example 3 · NetScaler**

```kusto
Netscaler_Logs_CL
| where Payload contains "errno"
```

#### 2.75 SQL vs KQL: string wildcard (LIKE 'abc%')

*01-KQL.pptx · slide 64* — SQL: `SELECT * FROM Infoblox_DNS_CL WHERE DnsQuery LIKE 'login%'`

**Example 1 · DNS**

```kusto
Infoblox_DNS_CL
| where DnsQuery startswith "login"
```

**Example 2 · Firewall**

```kusto
Palo_FW_CL
| where SrcIP startswith "10.158."
```

**Example 3 · DHCP**

```kusto
Infoblox_DHCP_CL
| where ClientHostname startswith "WP"
```

#### 2.76 SQL vs KQL: date comparison, last 1 day

*01-KQL.pptx · slide 64* — SQL: `SELECT * FROM Palo_FW_CL WHERE TimeGenerated > GETDATE() - 1`

**Example 1 · Firewall (static sample: returns data only while it is under a day old)**

```kusto
Palo_FW_CL
| where TimeGenerated > ago(1d)
```

**Example 2 · DNS, last 7 days**

```kusto
Infoblox_DNS_CL
| where TimeGenerated > ago(7d)
```

**Example 3 · DHCP, last 30 days**

```kusto
Infoblox_DHCP_CL
| where TimeGenerated > ago(30d)
```

#### 2.77 SQL vs KQL: date range (BETWEEN)

*01-KQL.pptx · slide 64* — SQL: `SELECT * FROM Palo_FW_CL WHERE TimeGenerated BETWEEN '2026-11-16 20:02:00' AND '2026-11-16 20:02:10'`

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| where TimeGenerated between (datetime(2026-11-16 20:02:00) .. datetime(2026-11-16 20:02:10))
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| where TimeGenerated between (datetime(2026-11-16 19:51:00) .. datetime(2026-11-16 19:52:00))
```

**Example 3 · DHCP**

```kusto
Infoblox_DHCP_CL
| where TimeGenerated between (datetime(2026-11-16 13:03:00) .. datetime(2026-11-16 13:04:00))
```

#### 2.78 SQL vs KQL: boolean comparison (WHERE NOT flag)

*01-KQL.pptx · slide 64* — SQL: `SELECT * FROM Palo_FW_CL WHERE NOT IsBlocked`

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| extend IsBlocked = Action in ("deny", "reset-both", "block-url")
| where IsBlocked == false
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| extend IsFailure = EventType == "QueryFailure"
| where IsFailure == false
```

**Example 3 · DHCP**

```kusto
Infoblox_DHCP_CL
| extend IsAbandoned = EventType == "AbandonedLease"
| where not(IsAbandoned)
```

#### 2.79 SQL vs KQL: sort (ORDER BY)

*01-KQL.pptx · slide 64* — SQL: `SELECT SrcIP, TimeGenerated FROM Palo_FW_CL ORDER BY TimeGenerated ASC`

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| project SrcIP, TimeGenerated
| order by TimeGenerated asc
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| project ClientIP, DnsQuery, TimeGenerated
| order by TimeGenerated desc
```

**Example 3 · NetScaler**

```kusto
Netscaler_Logs_CL
| project DeviceName, EventType, TimeGenerated
| order by TimeGenerated asc
```

#### 2.80 SQL vs KQL: distinct (SELECT DISTINCT)

*01-KQL.pptx · slide 64* — SQL: `SELECT DISTINCT Action, Protocol FROM Palo_FW_CL`

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| summarize by Action, Protocol
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| summarize by EventType, QueryType
```

**Example 3 · NetScaler**

```kusto
Netscaler_Logs_CL
| summarize by Module, EventType
```

#### 2.81 SQL vs KQL: grouping and aggregation (GROUP BY)

*01-KQL.pptx · slide 64* — SQL: `SELECT SrcIP, AVG(BytesOut) FROM Palo_FW_CL GROUP BY SrcIP`

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| summarize avg(BytesOut) by SrcIP
```

**Example 2 · NetScaler**

```kusto
Netscaler_Logs_CL
| summarize avg(BytesReceived) by DeviceName
```

**Example 3 · DNS**

```kusto
Infoblox_DNS_CL
| summarize avg(strlen(DnsQuery)) by QueryType
```

#### 2.82 SQL vs KQL: column aliases and extend

*01-KQL.pptx · slide 64* — SQL: `SELECT SrcIP AS Source, AVG(BytesOut) AS AvgOut FROM Palo_FW_CL GROUP BY SrcIP`

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| summarize AvgOut = avg(BytesOut) by SrcIP
| project Source = SrcIP, AvgOut
```

**Example 2 · NetScaler**

```kusto
Netscaler_Logs_CL
| summarize AvgReceived = avg(BytesReceived) by DeviceName
| project Appliance = DeviceName, AvgReceived
```

**Example 3 · DNS**

```kusto
Infoblox_DNS_CL
| summarize AvgLength = avg(strlen(DnsQuery)) by QueryType
| project Type = QueryType, AvgLength
```


---

## Part 2 · 02-KQL.pptx (Using KQL)


### 3. Filtering with KQL (slides 5–10)

#### 3.1 Query construction flow: data, filter and prepare, analyze, present

*02-KQL.pptx · slide 6* — Each stage reduces or reshapes the result; pivot back to refine.

**Example 1 · Firewall**

```kusto
Palo_FW_CL                                  // Data
| where Action == "allow"                   // Filter and prepare
| summarize count() by SrcIP                // Analyze
| top 10 by count_                          // Present
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL                             // Data
| where EventType == "Query"                // Filter and prepare
| summarize count() by DnsQuery             // Analyze
| top 10 by count_                          // Present
```

**Example 3 · NetScaler**

```kusto
Netscaler_Logs_CL                          // Data
| where isnotempty(ClientIP)                // Filter and prepare
| summarize count() by ClientIP, Module     // Analyze
| top 10 by count_                          // Present
```

#### 3.2 where: filter rows with a predicate, then count

*02-KQL.pptx · slide 7* — Syntax: T | where Predicate.

**Example 1 · Firewall: how many blocked sessions per source?**

```kusto
Palo_FW_CL
| where Action == "deny"
| summarize DeniedCount = count() by SrcIP
```

**Example 2 · DNS: how many failures per client?**

```kusto
Infoblox_DNS_CL
| where EventType == "QueryFailure"
| summarize FailureCount = count() by ClientIP
```

**Example 3 · DHCP: how many abandoned leases per IP?**

```kusto
Infoblox_DHCP_CL
| where EventType == "AbandonedLease"
| summarize AbandonedCount = count() by LeaseIP
```

#### 3.3 Predicate operators, strings (1/2): ==, has, contains

*02-KQL.pptx · slide 7* — String comparisons.

**Example 1 · == (exact)**

```kusto
Palo_FW_CL
| where App == "teamviewer-base"
```

**Example 2 · has (whole term)**

```kusto
Infoblox_DNS_CL
| where DnsQuery has "signalfx"
```

**Example 3 · contains (substring)**

```kusto
Netscaler_Logs_CL
| where HttpUrl contains "Citrix"
```

#### 3.4 Predicate operators, strings (2/2): !contains, startswith, endswith, matches regex

*02-KQL.pptx · slide 7* — String comparisons.

**Example 1 · !contains and startswith**

```kusto
Infoblox_DNS_CL
| where DnsQuery !contains "microsoft" and DnsQuery startswith "e"
```

**Example 2 · endswith**

```kusto
Infoblox_DNS_CL
| where DnsQuery endswith ".com"
```

**Example 3 · matches regex**

```kusto
Palo_FW_CL
| where Rule matches regex "^Azure.*-[0-9]$"
```

#### 3.5 Predicate operators, numeric and date: ==, !=, <, >, <=, >=

*02-KQL.pptx · slide 7* — Numbers are not quoted.

**Example 1 · Equals and not equals**

```kusto
Palo_FW_CL
| where DestPort == 443 and SrcPort != 0
```

**Example 2 · Greater and less than**

```kusto
Palo_FW_CL
| where BytesOut > 100000 and DestPort <= 1024
```

**Example 3 · Dates**

```kusto
Infoblox_DHCP_CL
| where TimeGenerated >= datetime(2026-11-16 13:03:00) and TimeGenerated < datetime(2026-11-16 13:04:00)
```

#### 3.6 Predicate operators, lookup: in, !in, has_any

*02-KQL.pptx · slide 7* — Match against lists.

**Example 1 · in**

```kusto
Palo_FW_CL
| where Action in ("deny", "reset-both")
```

**Example 2 · !in**

```kusto
Infoblox_DNS_CL
| where QueryType !in ("A", "AAAA")
```

**Example 3 · has_any**

```kusto
Infoblox_DNS_CL
| where DnsQuery has_any ("microsoft", "azure", "office")
```

#### 3.7 Combine predicates with and, or and not()

*02-KQL.pptx · slide 7* — Use parentheses when mixing and with or.

**Example 1 · and**

```kusto
Palo_FW_CL
| where Action == "deny" and DestPort == 443
```

**Example 2 · or inside parentheses**

```kusto
Palo_FW_CL
| where (SrcIP == "10.158.8.10" or DestIP == "10.158.8.10") and Action == "allow"
```

**Example 3 · not()**

```kusto
Infoblox_DNS_CL
| where not(QueryType in ("A", "AAAA"))
```

#### 3.8 where examples: time, conditions, case-insensitive match, lists and ipv4_is_match

*02-KQL.pptx · slide 8* — The same building blocks on different tables.

**Example 1 · Time filter and a condition**

```kusto
Infoblox_DHCP_CL
| where TimeGenerated > ago(30d) and EventType == "DHCPREQUEST"   // lease request
```

**Example 2 · Case-insensitive and a list**

```kusto
Palo_FW_CL
| where TimeGenerated > ago(30d)
| where Protocol =~ "TCP"
| where DestPort in (80, 443)
```

**Example 3 · Subnet match**

```kusto
Netscaler_Logs_CL
| where TimeGenerated > ago(30d)
| where isnotempty(ClientIP) and ipv4_is_match(ClientIP, "10.238.0.0/16")
```

#### 3.9 Lab: filter on different columns

*02-KQL.pptx · slides 9–10* — Pick the column that answers the question.

**Example 1 · Firewall zone**

```kusto
Palo_FW_CL
| where SrcZone == "internal" and DestZone == "external"
```

**Example 2 · DNS server**

```kusto
Infoblox_DNS_CL
| where DNSServerIP == "10.1.132.14"
```

**Example 3 · NetScaler appliance**

```kusto
Netscaler_Logs_CL
| where DeviceName == "cat2yc3netscaler02"
```

#### 3.10 Lab: learn how to use predicate operators

*02-KQL.pptx · slides 9–10* — Try several operators on the same column.

**Example 1 · Exact**

```kusto
Infoblox_DNS_CL
| where DnsQuery == "wpad.westjet.priv"
```

**Example 2 · Term and prefix**

```kusto
Infoblox_DNS_CL
| where DnsQuery has "endpoint" or DnsQuery startswith "login"
```

**Example 3 · Suffix and exclusion**

```kusto
Infoblox_DNS_CL
| where DnsQuery endswith ".com" and DnsQuery !contains "microsoft"
```

#### 3.11 Lab: learn how to use lookups

*02-KQL.pptx · slides 9–10* — Lookups with in, !in and has_any.

**Example 1 · in**

```kusto
Palo_FW_CL
| where App in ("teamviewer-base", "quic-base", "ssl")
```

**Example 2 · !in**

```kusto
Infoblox_DHCP_CL
| where EventType !in ("DHCPREQUEST", "DHCPACK")
```

**Example 3 · has_any**

```kusto
Netscaler_Logs_CL
| where Payload has_any ("errno", "nFactor", "serialized")
```


### 4. Analyzing with KQL (slides 11–19)

#### 4.1 summarize syntax: T | summarize Aggregation [by Group Expression]

*02-KQL.pptx · slide 12* — Produces a table that aggregates the input table.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| summarize count() by SrcIP
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| summarize count() by ClientIP
```

**Example 3 · DHCP**

```kusto
Infoblox_DHCP_CL
| summarize count() by ClientHostname
```

#### 4.2 Simple aggregation functions: count() and dcount()

*02-KQL.pptx · slide 12* — Rows and distinct values.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| summarize Sessions = count(), Sources = dcount(SrcIP) by Action
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| summarize Queries = count(), Clients = dcount(ClientIP) by QueryType
```

**Example 3 · NetScaler**

```kusto
Netscaler_Logs_CL
| summarize Events = count(), Clients = dcount(ClientIP) by Module
```

#### 4.3 Simple aggregation functions: sum() and avg()

*02-KQL.pptx · slide 12* — Totals and averages of numeric columns.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| summarize TotalOut = sum(BytesOut), AvgOut = avg(BytesOut) by App
```

**Example 2 · NetScaler**

```kusto
Netscaler_Logs_CL
| where isnotnull(BytesReceived)
| summarize TotalReceived = sum(BytesReceived), AvgReceived = avg(BytesReceived) by DeviceName
```

**Example 3 · DNS name length**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| summarize AvgLength = avg(strlen(DnsQuery)) by QueryType
```

#### 4.4 Simple aggregation functions: min() and max()

*02-KQL.pptx · slide 12* — Smallest and largest values.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| summarize SmallestOut = min(BytesOut), LargestOut = max(BytesOut) by Action
```

**Example 2 · DHCP time span**

```kusto
Infoblox_DHCP_CL
| summarize First = min(TimeGenerated), Last = max(TimeGenerated) by EventType
```

**Example 3 · NetScaler time span**

```kusto
Netscaler_Logs_CL
| summarize First = min(TimeGenerated), Last = max(TimeGenerated) by DeviceName
```

#### 4.5 Advanced functions: arg_min()

*02-KQL.pptx · slide 12* — Return the row (or a column) with the smallest value.

**Example 1 · Firewall: smallest session per source**

```kusto
Palo_FW_CL
| where isnotnull(BytesOut)
| summarize arg_min(BytesOut, DestIP, App) by SrcIP
```

**Example 2 · DHCP: first event per IP**

```kusto
Infoblox_DHCP_CL
| summarize arg_min(TimeGenerated, EventType) by LeaseIP
```

**Example 3 · NetScaler: first event per appliance**

```kusto
Netscaler_Logs_CL
| summarize arg_min(TimeGenerated, *) by DeviceName
| project TimeGenerated, DeviceName, Module, EventType
```

#### 4.6 Advanced functions: arg_max()

*02-KQL.pptx · slide 12* — Return the row (or a column) with the largest value.

**Example 1 · Firewall: largest session per source**

```kusto
Palo_FW_CL
| where isnotnull(BytesOut)
| summarize arg_max(BytesOut, DestIP, App) by SrcIP
```

**Example 2 · DNS: latest event per client**

```kusto
Infoblox_DNS_CL
| summarize arg_max(TimeGenerated, EventType, DnsQuery) by ClientIP
```

**Example 3 · NetScaler: largest download per client**

```kusto
Netscaler_Logs_CL
| where isnotnull(BytesReceived)
| summarize arg_max(BytesReceived, DeviceName) by ClientIP
```

#### 4.7 Advanced functions: make_list()

*02-KQL.pptx · slide 12* — Collect values into an array.

**Example 1 · Firewall destinations per source**

```kusto
Palo_FW_CL
| summarize Destinations = make_list(DestIP) by SrcIP
| take 10
```

**Example 2 · DNS names per client**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| summarize Names = make_list(DnsQuery) by ClientIP
| take 10
```

**Example 3 · DHCP events per IP**

```kusto
Infoblox_DHCP_CL
| summarize Events = make_list(EventType) by LeaseIP
| take 10
```

#### 4.8 Advanced functions: countif()

*02-KQL.pptx · slide 12* — Count only the rows that match a condition.

**Example 1 · Firewall: blocked vs total**

```kusto
Palo_FW_CL
| summarize Total = count(), Blocked = countif(Action in ("deny", "reset-both", "block-url")) by SrcIP
| top 10 by Blocked
```

**Example 2 · DNS: failures vs total**

```kusto
Infoblox_DNS_CL
| summarize Total = count(), Failures = countif(EventType == "QueryFailure") by ClientIP
| top 10 by Failures
```

**Example 3 · DHCP: acknowledgements vs requests**

```kusto
Infoblox_DHCP_CL
| summarize Requests = countif(EventType == "DHCPREQUEST"), Acks = countif(EventType == "DHCPACK") by DHCPServerIP
```

#### 4.9 summarize examples: distinct count by a group

*02-KQL.pptx · slide 13* — Count distinct values of a column per group.

**Example 1 · Firewall: distinct destinations per action**

```kusto
Palo_FW_CL
| where TimeGenerated > ago(30d)
| summarize dcount(DestIP) by Action
```

**Example 2 · DNS: distinct names per query type**

```kusto
Infoblox_DNS_CL
| where TimeGenerated > ago(30d) and EventType == "Query"
| summarize dcount(DnsQuery) by QueryType
```

**Example 3 · NetScaler: distinct clients per module**

```kusto
Netscaler_Logs_CL
| where TimeGenerated > ago(30d) and isnotempty(ClientIP)
| summarize dcount(ClientIP) by Module
```

#### 4.10 summarize examples: count by two columns

*02-KQL.pptx · slide 13* — Group by a pair of columns.

**Example 1 · Firewall: source and destination zone**

```kusto
Palo_FW_CL
| where TimeGenerated > ago(30d)
| summarize count() by SrcZone, DestZone
```

**Example 2 · DNS: client and query type**

```kusto
Infoblox_DNS_CL
| where TimeGenerated > ago(30d) and EventType == "Query"
| summarize count() by ClientIP, QueryType
```

**Example 3 · DHCP: server and event type**

```kusto
Infoblox_DHCP_CL
| where TimeGenerated > ago(30d)
| summarize count() by DHCPServerIP, EventType
```

#### 4.11 summarize examples: the default column name (use count = count() to override)

*02-KQL.pptx · slide 13* — Note the default column name.

**Example 1 · Default count_**

```kusto
Palo_FW_CL
| summarize count() by App
```

**Example 2 · Overridden name**

```kusto
Palo_FW_CL
| summarize Sessions = count() by App
```

**Example 3 · Overridden on DNS**

```kusto
Infoblox_DNS_CL
| summarize Events = count() by EventType
```

#### 4.12 distinct: the shortcut for distinct combinations of columns

*02-KQL.pptx · slide 14* — Syntax: T | distinct Column1, Column2.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| distinct SrcZone, DestZone
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| distinct DNSServerIP, EventType
```

**Example 3 · NetScaler**

```kusto
Netscaler_Logs_CL
| distinct DeviceName, Module
```

#### 4.13 project: the shortcut to choose columns

*02-KQL.pptx · slide 14* — Syntax: T | project ColumnName[=Expression].

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| project SrcIP, DestIP, App
```

**Example 2 · DHCP**

```kusto
Infoblox_DHCP_CL
| project LeaseIP, ClientHostname, ClientMAC
```

**Example 3 · NetScaler**

```kusto
Netscaler_Logs_CL
| project DeviceName, ClientIP, RequestHost
```

#### 4.14 arg_max(): the whole latest row per group

*02-KQL.pptx · slide 15* — arg_max(TimeGenerated, *) returns every column of the latest row.

**Example 1 · Firewall: latest session per source**

```kusto
Palo_FW_CL
| where TimeGenerated > ago(30d)
| summarize arg_max(TimeGenerated, *) by SrcIP
| project TimeGenerated, SrcIP, DestIP, Action
```

**Example 2 · DNS: latest event per client**

```kusto
Infoblox_DNS_CL
| where TimeGenerated > ago(30d)
| summarize arg_max(TimeGenerated, *) by ClientIP
| project TimeGenerated, ClientIP, DnsQuery, EventType
```

**Example 3 · DHCP: latest event per hostname**

```kusto
Infoblox_DHCP_CL
| where isnotempty(ClientHostname)
| summarize arg_max(TimeGenerated, *) by ClientHostname
| project TimeGenerated, ClientHostname, LeaseIP, EventType
```

#### 4.15 arg_max(): one column of the latest row

*02-KQL.pptx · slide 15* — arg_max(TimeGenerated, Column) returns just the columns you name.

**Example 1 · Firewall: last destination per source**

```kusto
Palo_FW_CL
| summarize arg_max(TimeGenerated, DestIP) by SrcIP
```

**Example 2 · DNS: last name per client**

```kusto
Infoblox_DNS_CL
| summarize arg_max(TimeGenerated, DnsQuery) by ClientIP
```

**Example 3 · NetScaler: last event per client**

```kusto
Netscaler_Logs_CL
| where isnotempty(ClientIP)
| summarize arg_max(TimeGenerated, EventType) by ClientIP
```

#### 4.16 arg_min(): the oldest row per group

*02-KQL.pptx · slide 15* — Mirror image of arg_max.

**Example 1 · Firewall: first destination per source**

```kusto
Palo_FW_CL
| summarize arg_min(TimeGenerated, DestIP) by SrcIP
```

**Example 2 · DNS: first name per client**

```kusto
Infoblox_DNS_CL
| summarize arg_min(TimeGenerated, DnsQuery) by ClientIP
```

**Example 3 · DHCP: first event per MAC**

```kusto
Infoblox_DHCP_CL
| where isnotempty(ClientMAC)
| summarize arg_min(TimeGenerated, EventType) by ClientMAC
```

#### 4.17 Filter out top or bottom rows: the last activity per key

*02-KQL.pptx · slide 16* — Keep the latest row per entity, then filter on it.

**Example 1 · Firewall sources whose last action was a block**

```kusto
Palo_FW_CL
| summarize arg_max(TimeGenerated, *) by SrcIP
| where Action in ("deny", "reset-both", "block-url")
| project TimeGenerated, SrcIP, DestIP, Action
```

**Example 2 · DNS clients whose last event was a failure**

```kusto
Infoblox_DNS_CL
| summarize arg_max(TimeGenerated, *) by ClientIP
| where EventType == "QueryFailure"
| project TimeGenerated, ClientIP, DnsQuery, FailureReason
```

**Example 3 · DHCP addresses whose last event was an abandoned lease**

```kusto
Infoblox_DHCP_CL
| summarize arg_max(TimeGenerated, *) by LeaseIP
| where EventType == "AbandonedLease"
| project TimeGenerated, LeaseIP, EventType
```

#### 4.18 summarize to prepare make_list(): duplicates are kept

*02-KQL.pptx · slide 17* — Returns an array of all values in the group.

**Example 1 · Firewall destinations**

```kusto
Palo_FW_CL
| summarize make_list(DestIP) by SrcIP
```

**Example 2 · DNS names**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| summarize make_list(DnsQuery) by ClientIP
```

**Example 3 · NetScaler events**

```kusto
Netscaler_Logs_CL
| summarize make_list(EventType) by DeviceName
```

#### 4.19 make_list() with distinct first: no duplicates

*02-KQL.pptx · slide 17* — distinct before make_list removes duplicates.

**Example 1 · Firewall: all blocked destination IPs in one list**

```kusto
Palo_FW_CL
| where Action in ("deny", "reset-both", "block-url")
| distinct DestIP
| summarize make_list(DestIP)
```

**Example 2 · DNS: all failing names in one list**

```kusto
Infoblox_DNS_CL
| where EventType == "QueryFailure"
| distinct DnsQuery
| summarize make_list(DnsQuery)
```

**Example 3 · NetScaler: all client IPs that used the SSL VPN**

```kusto
Netscaler_Logs_CL
| where Module == "SSLVPN" and isnotempty(ClientIP)
| distinct ClientIP
| summarize make_list(ClientIP)
```

#### 4.20 make_set(): distinct values in an array

*02-KQL.pptx · slide 18* — No duplicates, optional maximum size.

**Example 1 · Firewall: apps per source**

```kusto
Palo_FW_CL
| summarize make_set(App) by SrcIP
```

**Example 2 · DNS: query types per client**

```kusto
Infoblox_DNS_CL
| summarize make_set(QueryType) by ClientIP
```

**Example 3 · DHCP: event types per IP, at most 5**

```kusto
Infoblox_DHCP_CL
| summarize make_set(EventType, 5) by LeaseIP
```

#### 4.21 Lab: summarize by to get information about shares and connections

*02-KQL.pptx · slide 19* — Connections and distinct peers per entity.

**Example 1 · Firewall: connections and distinct destinations per source**

```kusto
Palo_FW_CL
| summarize Connections = count(), Destinations = dcount(DestIP) by SrcIP
| top 10 by Connections
```

**Example 2 · NetScaler: connections and bytes per client**

```kusto
Netscaler_Logs_CL
| where EventType == "TCPCONNSTAT"
| summarize Connections = count(), Received = sum(BytesReceived) by ClientIP
| top 10 by Connections
```

**Example 3 · DNS: queries and distinct names per client**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| summarize Queries = count(), Names = dcount(DnsQuery) by ClientIP
| top 10 by Queries
```

#### 4.22 Lab: arg_max to find the most recent item

*02-KQL.pptx · slide 19* — The most recent event of each kind.

**Example 1 · Firewall: most recent event per rule**

```kusto
Palo_FW_CL
| summarize arg_max(TimeGenerated, SrcIP, DestIP, Action) by Rule
```

**Example 2 · DHCP: most recent event per DHCP server**

```kusto
Infoblox_DHCP_CL
| summarize arg_max(TimeGenerated, EventType, LeaseIP) by DHCPServerIP
```

**Example 3 · NetScaler: most recent event per module**

```kusto
Netscaler_Logs_CL
| summarize arg_max(TimeGenerated, EventType, DeviceName) by Module
```


### 5. Presenting with KQL (slides 20–23)

#### 5.1 extend: calculated columns that are not stored

*02-KQL.pptx · slide 21* — The new column is available in the following stages.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| extend TotalBytes = BytesIn + BytesOut
| where TotalBytes > 1000000
| project TimeGenerated, SrcIP, DestIP, TotalBytes
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| extend Tld = toupper(tostring(split(DnsQuery, ".")[-1]))
| summarize count() by Tld
```

**Example 3 · NetScaler**

```kusto
Netscaler_Logs_CL
| extend Source = toupper(DeviceName)
| summarize count() by Source
```

#### 5.2 project-rename: change a column name

*02-KQL.pptx · slide 21* — Use project-rename to rename without choosing columns.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| project-rename Source = SrcIP, Destination = DestIP
| take 10
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| project-rename Client = ClientIP, Name = DnsQuery
| take 10
```

**Example 3 · DHCP**

```kusto
Infoblox_DHCP_CL
| project-rename Address = LeaseIP, Host = ClientHostname
| take 10
```

#### 5.3 bin(): time series buckets

*02-KQL.pptx · slide 22* — bin(value, roundTo) groups values into buckets; use it in summarize.

**Example 1 · Firewall per 10 seconds**

```kusto
Palo_FW_CL
| summarize count() by bin(TimeGenerated, 10s)
```

**Example 2 · DNS per 5 seconds**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| summarize count() by bin(TimeGenerated, 5s)
```

**Example 3 · NetScaler per minute**

```kusto
Netscaler_Logs_CL
| summarize count() by bin(TimeGenerated, 1m)
| render timechart
```

#### 5.4 render timechart

*02-KQL.pptx · slide 23* — Lines over time.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| summarize count() by bin(TimeGenerated, 5s)
| render timechart
```

**Example 2 · DHCP**

```kusto
Infoblox_DHCP_CL
| summarize count() by bin(TimeGenerated, 1m)
| render timechart
```

**Example 3 · NetScaler by module**

```kusto
Netscaler_Logs_CL
| summarize count() by bin(TimeGenerated, 1m), Module
| render timechart
```

#### 5.5 render areachart

*02-KQL.pptx · slide 23* — Stacked or filled areas over time.

**Example 1 · Firewall by action**

```kusto
Palo_FW_CL
| summarize count() by bin(TimeGenerated, 5s), Action
| render areachart
```

**Example 2 · DNS by query type**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| summarize count() by bin(TimeGenerated, 2s), QueryType
| render areachart
```

**Example 3 · DHCP by event type**

```kusto
Infoblox_DHCP_CL
| summarize count() by bin(TimeGenerated, 1m), EventType
| render areachart
```

#### 5.6 render barchart

*02-KQL.pptx · slide 23* — Horizontal bars for categories.

**Example 1 · Firewall sessions per application**

```kusto
Palo_FW_CL
| summarize Sessions = count() by App
| top 8 by Sessions
| render barchart
```

**Example 2 · DNS queries per client**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| summarize Queries = count() by ClientIP
| top 8 by Queries
| render barchart
```

**Example 3 · NetScaler events per event type**

```kusto
Netscaler_Logs_CL
| summarize Events = count() by EventType
| top 8 by Events
| render barchart
```

#### 5.7 render columnchart

*02-KQL.pptx · slide 23* — Vertical columns for categories.

**Example 1 · Firewall sessions per action**

```kusto
Palo_FW_CL
| summarize Sessions = count() by Action
| render columnchart
```

**Example 2 · DNS events per type**

```kusto
Infoblox_DNS_CL
| summarize Events = count() by EventType
| render columnchart
```

**Example 3 · DHCP events per type**

```kusto
Infoblox_DHCP_CL
| summarize Events = count() by EventType
| render columnchart
```

#### 5.8 render piechart

*02-KQL.pptx · slide 23* — Share of a whole.

**Example 1 · Firewall protocol share**

```kusto
Palo_FW_CL
| where isnotempty(Protocol)
| summarize count() by Protocol
| render piechart
```

**Example 2 · DNS query type share**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| summarize count() by QueryType
| render piechart
```

**Example 3 · NetScaler module share**

```kusto
Netscaler_Logs_CL
| summarize count() by Module
| render piechart
```

#### 5.9 render scatterchart

*02-KQL.pptx · slide 23* — Two numeric dimensions.

**Example 1 · Firewall bytes in vs out per source**

```kusto
Palo_FW_CL
| where isnotnull(BytesIn) and isnotnull(BytesOut)
| summarize BytesIn = sum(BytesIn), BytesOut = sum(BytesOut) by SrcIP
| render scatterchart
```

**Example 2 · NetScaler bytes sent vs received per client**

```kusto
Netscaler_Logs_CL
| where isnotnull(BytesReceived)
| summarize Sent = sum(BytesSent), Received = sum(BytesReceived) by ClientIP
| render scatterchart
```

**Example 3 · DNS queries vs distinct names per client**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| summarize Queries = count(), Names = dcount(DnsQuery) by ClientIP
| render scatterchart
```


### 6. Advanced KQL operations (slides 24–33)

#### 6.1 let: declare and reuse a variable (an IP)

*02-KQL.pptx · slide 25* — The let statement ends with a semicolon.

**Example 1 · Activity from an IP in the firewall**

```kusto
// Activity from an IP
let IP = "10.158.8.10";
Palo_FW_CL
| where SrcIP == IP or DestIP == IP
```

**Example 2 · DNS activity from a client**

```kusto
// DNS activity from a client
let IP = "10.192.132.14";
Infoblox_DNS_CL
| where ClientIP == IP
| project TimeGenerated, DnsQuery, QueryType
```

**Example 3 · DHCP activity for an address**

```kusto
// DHCP activity for an address
let IP = "10.216.132.166";
Infoblox_DHCP_CL
| where LeaseIP == IP
| project TimeGenerated, EventType, ClientHostname
```

#### 6.2 let: a lookback timespan and a name

*02-KQL.pptx · slide 25* — Define the window and the entity once, reuse them.

**Example 1 · Firewall**

```kusto
let lookback = 30d;
let App_ = "ssl";
Palo_FW_CL
| where TimeGenerated > ago(lookback)
| where App == App_
| project TimeGenerated, SrcIP, App, Action
```

**Example 2 · DNS**

```kusto
let lookback = 30d;
let Client = "10.192.132.14";
Infoblox_DNS_CL
| where TimeGenerated > ago(lookback)
| where ClientIP == Client
| project TimeGenerated, ClientIP, DnsQuery
```

**Example 3 · NetScaler**

```kusto
let lookback = 30d;
let Appliance = "cat2yc3netscaler02";
Netscaler_Logs_CL
| where TimeGenerated > ago(lookback)
| where DeviceName == Appliance
| project TimeGenerated, DeviceName, Module, EventType
```

#### 6.3 let: a time value computed with ago()

*02-KQL.pptx · slide 25* — let lookback = ago(7d) holds a datetime.

**Example 1 · Firewall**

```kusto
let lookback = ago(30d);
let Host = "10.158.8.10";
Palo_FW_CL
| where TimeGenerated > lookback
| where SrcIP == Host
| project TimeGenerated, SrcIP, DestIP, Action
```

**Example 2 · DHCP**

```kusto
let lookback = ago(30d);
let Server = "10.1.132.14";
Infoblox_DHCP_CL
| where TimeGenerated > lookback
| where DHCPServerIP == Server
| project TimeGenerated, EventType, LeaseIP
```

**Example 3 · DNS**

```kusto
let lookback = ago(30d);
let QType = "A";
Infoblox_DNS_CL
| where TimeGenerated > lookback
| where QueryType == QType
| project TimeGenerated, ClientIP, DnsQuery
```

#### 6.4 let: declare a dynamic list with datatable

*02-KQL.pptx · slide 26* — A one-field table can be used as a list.

**Example 1 · Firewall: suspicious sources**

```kusto
let suspiciousSources = datatable(ip: string) ["10.238.151.17", "10.238.150.53"];
Palo_FW_CL
| where SrcIP in (suspiciousSources)
```

**Example 2 · DNS: suspicious names**

```kusto
let suspiciousNames = datatable(name: string) ["wpad.westjet.priv", "ingest.us1.signalfx.com"];
Infoblox_DNS_CL
| where DnsQuery in (suspiciousNames)
```

**Example 3 · NetScaler: suspicious clients**

```kusto
let suspiciousClients = datatable(ip: string) ["57.253.134.36", "10.103.218.10"];
Netscaler_Logs_CL
| where ClientIP in (suspiciousClients)
```

#### 6.5 let: declare a table 'view' that is the result of a query

*02-KQL.pptx · slide 26* — LowActivity-style views.

**Example 1 · Firewall**

```kusto
let LowActivitySources = Palo_FW_CL
    | summarize cnt = count() by SrcIP
    | where cnt < 5;
LowActivitySources
| where SrcIP startswith "10."
```

**Example 2 · DNS**

```kusto
let LowActivityClients = Infoblox_DNS_CL
    | summarize cnt = count() by ClientIP
    | where cnt < 3;
LowActivityClients
| where ClientIP startswith "10.216."
```

**Example 3 · DHCP**

```kusto
let LowActivityHosts = Infoblox_DHCP_CL
    | where isnotempty(ClientHostname)
    | summarize cnt = count() by ClientHostname
    | where cnt < 5;
LowActivityHosts
| where ClientHostname startswith "W"
```

#### 6.6 JSON and arrays: todynamic()

*02-KQL.pptx · slide 27* — Convert a string into a dynamic (JSON) value.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| extend Raw = tostring(bag_pack("src", SrcIP, "dst", DestIP, "action", Action))
| extend Props = todynamic(Raw)
| project Raw, Props
| take 5
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| extend Raw = tostring(bag_pack("client", ClientIP, "name", DnsQuery))
| extend Props = todynamic(Raw)
| project Raw, Props
| take 5
```

**Example 3 · DHCP**

```kusto
Infoblox_DHCP_CL
| extend Raw = tostring(bag_pack("ip", LeaseIP, "event", EventType))
| extend Props = todynamic(Raw)
| project Raw, Props
| take 5
```

#### 6.7 JSON and arrays: JsonField.Key and JsonField["Key"]

*02-KQL.pptx · slide 27* — Two notations to refer to a field of a dynamic value.

**Example 1 · Dot notation**

```kusto
Palo_FW_CL
| extend Props = bag_pack("src", SrcIP, "action", Action)
| project SrcIP = Props.src, Action = Props.action
| take 5
```

**Example 2 · Bracket notation**

```kusto
Infoblox_DNS_CL
| extend Props = bag_pack("client", ClientIP, "name", DnsQuery)
| project Client = Props["client"], Name = Props["name"]
| take 5
```

**Example 3 · Bracket notation for a key with a space**

```kusto
Netscaler_Logs_CL
| extend Props = bag_pack("Device Name", DeviceName, "Module", Module)
| project Device = tostring(Props["Device Name"]), Module = tostring(Props.Module)
| take 5
```

#### 6.8 JSON and arrays: mv-expand creates a row per array value

*02-KQL.pptx · slide 27* — The easiest way to process arrays.

**Example 1 · Firewall: one row per destination**

```kusto
Palo_FW_CL
| summarize Destinations = make_set(DestIP) by SrcIP
| mv-expand Destination = Destinations to typeof(string)
| take 20
```

**Example 2 · DNS: one row per name**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| summarize Names = make_set(DnsQuery) by ClientIP
| mv-expand Name = Names to typeof(string)
| take 20
```

**Example 3 · DHCP: one row per event type**

```kusto
Infoblox_DHCP_CL
| summarize Events = make_set(EventType) by LeaseIP
| mv-expand EventName = Events to typeof(string)
| take 20
```

#### 6.9 JSON and arrays: mv-apply runs a query on each array value

*02-KQL.pptx · slide 27* — mv-apply = mv-expand + a sub-query.

**Example 1 · Firewall: count internal destinations per source**

```kusto
Palo_FW_CL
| summarize Destinations = make_set(DestIP) by SrcIP
| mv-apply Dest = Destinations to typeof(string) on (
    where Dest startswith "10."
    | summarize InternalDestinations = count())
| take 20
```

**Example 2 · DNS: keep only Microsoft names**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| summarize Names = make_set(DnsQuery) by ClientIP
| mv-apply Name = Names to typeof(string) on (
    where Name endswith "microsoft.com"
    | summarize MicrosoftNames = make_list(Name))
| take 20
```

**Example 3 · DHCP: count ACK-type events per IP**

```kusto
Infoblox_DHCP_CL
| summarize Events = make_list(EventType) by LeaseIP
| mv-apply E = Events to typeof(string) on (
    where E == "DHCPACK"
    | summarize Acks = count())
| take 20
```

#### 6.10 JSON examples: promote dynamic properties to columns

*02-KQL.pptx · slide 28* — The ExtendedProperties pattern: todynamic, then read keys.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| extend ExtendedProperties = bag_pack("Action Taken", Action, "Attacker IP", SrcIP)
| extend ActionTaken = ExtendedProperties["Action Taken"]
| extend AttackerIP = ExtendedProperties["Attacker IP"]
| project TimeGenerated, ActionTaken, AttackerIP
| take 5
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| extend ExtendedProperties = bag_pack("Client", ClientIP, "Name", DnsQuery)
| extend Client = ExtendedProperties.Client, Name = ExtendedProperties.Name
| project TimeGenerated, Client, Name
| take 5
```

**Example 3 · NetScaler**

```kusto
Netscaler_Logs_CL
| extend ExtendedProperties = bag_pack("Appliance", DeviceName, "EventName", EventType)
| extend Appliance = ExtendedProperties.Appliance, EventName = ExtendedProperties.EventName
| project TimeGenerated, Appliance, EventName
| take 5
```

#### 6.11 JSON examples: mv-expand an entity list

*02-KQL.pptx · slide 28* — One row per element of an array of entities.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| summarize Entities = make_list(DestIP) by SrcIP
| mv-expand entity = Entities
| take 20
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| summarize Entities = make_list(DnsQuery) by ClientIP
| mv-expand entity = Entities
| take 20
```

**Example 3 · NetScaler**

```kusto
Netscaler_Logs_CL
| where isnotempty(ClientIP)
| summarize Entities = make_list(EventType) by ClientIP
| mv-expand entity = Entities
| take 20
```

#### 6.12 JSON examples: mv-apply with where and extend

*02-KQL.pptx · slide 28* — Filter the array elements and build a value from them.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| summarize Entities = make_list(bag_pack("Type", "dest", "Name", DestIP, "Port", DestPort)) by SrcIP
| mv-apply entity = Entities on (
    where entity.Type == "dest"
    | extend dest = strcat(entity.Name, ":", entity.Port))
| take 20
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| summarize Entities = make_list(bag_pack("Type", "query", "Name", DnsQuery, "Class", QueryType)) by ClientIP
| mv-apply entity = Entities on (
    where entity.Type == "query"
    | extend lookup = strcat(entity.Name, " (", entity.Class, ")"))
| take 20
```

**Example 3 · DHCP**

```kusto
Infoblox_DHCP_CL
| summarize Entities = make_list(bag_pack("Type", "lease", "Mac", ClientMAC, "Host", ClientHostname)) by LeaseIP
| mv-apply entity = Entities on (
    where entity.Type == "lease"
    | extend device = strcat(entity.Host, " [", entity.Mac, "]"))
| take 20
```

#### 6.13 Parsing JSON: parse_json() with an index and a property

*02-KQL.pptx · slide 29* — parse_json(Entities)[0].Property style.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| take 10
| extend Entities = tostring(bag_pack_columns(SrcIP, DestIP))
| extend FirstSource = tostring(parse_json(Entities).SrcIP)
| extend FirstDestination = tostring(parse_json(Entities).DestIP)
| project SrcIP, DestIP, FirstSource, FirstDestination
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| take 10
| extend Entities = tostring(bag_pack("names", pack_array(DnsQuery, QueryType)))
| extend FirstName = tostring(parse_json(Entities).names[0])
| extend SecondItem = tostring(parse_json(Entities).names[1])
| project DnsQuery, FirstName, SecondItem
```

**Example 3 · DHCP**

```kusto
Infoblox_DHCP_CL
| take 10
| extend Entities = tostring(bag_pack("ids", pack_array(LeaseIP, ClientMAC)))
| extend LeaseIpFromJson = tostring(parse_json(Entities).ids[0])
| extend MacFromJson = tostring(parse_json(Entities).ids[1])
| project LeaseIP, LeaseIpFromJson, MacFromJson
```

#### 6.14 Parsing JSON: parse_json() with ["key"], then summarize

*02-KQL.pptx · slide 29* — Parse, then group and order.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| extend Raw = tostring(bag_pack("Machine Name", SrcIP, "File Name", App))
| extend Machine_Name_ = tostring(parse_json(Raw)["Machine Name"])
| extend File_Name_ = tostring(parse_json(Raw)["File Name"])
| summarize count() by Machine_Name_, File_Name_
| order by count_ desc
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| extend Raw = tostring(bag_pack("Client", ClientIP, "Type", QueryType))
| extend Client_ = tostring(parse_json(Raw)["Client"])
| extend Type_ = tostring(parse_json(Raw)["Type"])
| summarize count() by Client_, Type_
| order by count_ desc
```

**Example 3 · NetScaler**

```kusto
Netscaler_Logs_CL
| extend Raw = tostring(bag_pack("Appliance", DeviceName, "Module", Module))
| extend Appliance_ = tostring(parse_json(Raw)["Appliance"])
| extend Module_ = tostring(parse_json(Raw)["Module"])
| summarize count() by Appliance_, Module_
| order by count_ desc
```

#### 6.15 materialize(): cache a let result that is used more than once

*02-KQL.pptx · slide 30* — Faster and consistent when the named result is referenced several times.

**Example 1 · Firewall**

```kusto
let LowActivitySources = materialize(Palo_FW_CL
    | summarize cnt = count() by SrcIP
    | where cnt < 10);
LowActivitySources
| where SrcIP startswith "10.238."
```

**Example 2 · DNS**

```kusto
let LowActivityClients = materialize(Infoblox_DNS_CL
    | summarize cnt = count() by ClientIP
    | where cnt < 5);
LowActivityClients
| where ClientIP startswith "10.21"
```

**Example 3 · DHCP**

```kusto
let LowActivityHosts = materialize(Infoblox_DHCP_CL
    | where isnotempty(ClientHostname)
    | summarize cnt = count() by ClientHostname
    | where cnt < 10);
LowActivityHosts
| where ClientHostname contains "MXL"
```

#### 6.16 union: rows of two or more tables

*02-KQL.pptx · slide 31* — Takes two or more tables and returns the rows of all of them.

**Example 1 · Firewall and DNS stacked**

```kusto
union Palo_FW_CL, Infoblox_DNS_CL
| where TimeGenerated > ago(30d)
| summarize count()
```

**Example 2 · withsource and a filtered table**

```kusto
union withsource = Tlist Palo_FW_CL, Infoblox_DNS_CL
| where Tlist == "Palo_FW_CL" or EventType == "QueryFailure"
| summarize count() by Tlist
```

**Example 3 · DHCP and NetScaler by source table**

```kusto
union withsource = SourceTable Infoblox_DHCP_CL, Netscaler_Logs_CL
| summarize count() by SourceTable
```

#### 6.17 union with a wildcard on the table name

*02-KQL.pptx · slide 31* — Supports a wildcard to union multiple tables.

**Example 1 · All Infoblox tables**

```kusto
union withsource = SourceTable Infoblox_*
| summarize Records = count() by SourceTable
```

**Example 2 · Prefix on the firewall table, grouped by time**

```kusto
union withsource = SourceTable Palo*
| summarize Records = count() by SourceTable, bin(TimeGenerated, 10s)
| sort by TimeGenerated asc
```

**Example 3 · Prefix on the NetScaler table, ordered**

```kusto
union withsource = SourceTable Netscaler*
| summarize Records = count() by SourceTable, Module
| sort by Records asc
```

#### 6.18 join: merge rows of two tables on matching columns

*02-KQL.pptx · slide 32* — Syntax: LeftTable | join [JoinParameters] (RightTable) on Attributes.

**Example 1 · Firewall sessions with DNS activity from the same address**

```kusto
Palo_FW_CL
| take 500
| join (Infoblox_DNS_CL | where EventType == "Query") on $left.SrcIP == $right.ClientIP
| project SrcIP, DestIP, DnsQuery
| take 20
```

**Example 2 · DHCP leases that also appear in DNS**

```kusto
Infoblox_DHCP_CL
| where isnotempty(ClientHostname)
| join (Infoblox_DNS_CL) on $left.LeaseIP == $right.ClientIP
| project LeaseIP, ClientHostname, DnsQuery
| take 20
```

**Example 3 · NetScaler clients that also appear in the firewall**

```kusto
Netscaler_Logs_CL
| where isnotempty(ClientIP)
| join (Palo_FW_CL | where Action == "allow") on $left.ClientIP == $right.SrcIP
| project ClientIP, Module, DestIP, DestPort
| take 20
```

#### 6.19 join examples: innerunique with $left and $right

*02-KQL.pptx · slide 33* — Take a sample on the left, then join.

**Example 1 · Firewall to DNS**

```kusto
Palo_FW_CL
| where TimeGenerated > ago(30d)
| take 1000
| join kind = innerunique (Infoblox_DNS_CL) on $left.SrcIP == $right.ClientIP
| project SrcIP, DestIP, DnsQuery
| take 20
```

**Example 2 · DNS to DHCP**

```kusto
Infoblox_DNS_CL
| where TimeGenerated > ago(30d)
| take 1000
| join kind = innerunique (Infoblox_DHCP_CL) on $left.ClientIP == $right.LeaseIP
| project ClientIP, DnsQuery, ClientHostname
| take 20
```

**Example 3 · NetScaler to DHCP**

```kusto
Netscaler_Logs_CL
| where TimeGenerated > ago(30d) and isnotempty(ClientIP)
| take 1000
| join kind = innerunique (Infoblox_DHCP_CL) on $left.ClientIP == $right.LeaseIP
| project ClientIP, Module, ClientHostname
| take 20
```

#### 6.20 join examples: a default join on a common column

*02-KQL.pptx · slide 33* — Join on a column name that exists on both sides.

**Example 1 · Firewall and DNS on a renamed column**

```kusto
Palo_FW_CL
| where TimeGenerated > ago(30d)
| take 1000
| project IP = SrcIP, DestIP
| join (Infoblox_DNS_CL | project IP = ClientIP, DnsQuery) on IP
| take 20
```

**Example 2 · DHCP and NetScaler on a renamed column**

```kusto
Infoblox_DHCP_CL
| where TimeGenerated > ago(30d)
| take 1000
| project IP = LeaseIP, ClientHostname
| join (Netscaler_Logs_CL | project IP = ClientIP, Module) on IP
| take 20
```

**Example 3 · DNS and DHCP on a renamed column**

```kusto
Infoblox_DNS_CL
| where TimeGenerated > ago(30d)
| take 1000
| project IP = ClientIP, DnsQuery
| join (Infoblox_DHCP_CL | project IP = LeaseIP, ClientHostname) on IP
| take 20
```

#### 6.21 join examples: kind=inner with a lookup-style table

*02-KQL.pptx · slide 33* — Join to a summarized or reference table.

**Example 1 · Firewall to a table of busiest sources**

```kusto
Palo_FW_CL
| join kind = inner (Palo_FW_CL | summarize Sessions = count() by SrcIP | top 5 by Sessions) on SrcIP
| take 20
```

**Example 2 · DNS to a table of failing clients**

```kusto
Infoblox_DNS_CL
| join kind = inner (Infoblox_DNS_CL | where EventType == "QueryFailure" | summarize Failures = count() by ClientIP) on ClientIP
| project ClientIP, DnsQuery, Failures
| take 20
```

**Example 3 · DHCP to a table of chatty hosts**

```kusto
Infoblox_DHCP_CL
| join kind = inner (Infoblox_DHCP_CL | where isnotempty(ClientHostname) | summarize Events = count() by ClientHostname | top 3 by Events) on ClientHostname
| project TimeGenerated, ClientHostname, EventType, Events
| take 20
```


### 7. Optimizing queries (slides 34–45)

#### 7.1 Measuring query performance: keep test result sets small

*02-KQL.pptx · slides 35–37* — Avoid tests that return more than 30K results; summarize or limit while testing. Check Query details for time and data scanned.

**Example 1 · Count instead of returning rows**

```kusto
Palo_FW_CL
| count
```

**Example 2 · Limit rows while developing**

```kusto
Infoblox_DNS_CL
| take 100
```

**Example 3 · Summarize while developing**

```kusto
Netscaler_Logs_CL
| summarize count() by Module
```

#### 7.2 Cold data: each side of a join has its own TimeGenerated filter

*02-KQL.pptx · slides 38–39* — Scope every sub-query.

**Example 1 · Firewall and DNS**

```kusto
Palo_FW_CL
| where TimeGenerated > ago(30d)
| join kind = inner (Infoblox_DNS_CL | where TimeGenerated > ago(30d)) on $left.SrcIP == $right.ClientIP
| take 20
```

**Example 2 · DNS and DHCP**

```kusto
Infoblox_DNS_CL
| where TimeGenerated > ago(30d)
| join kind = inner (Infoblox_DHCP_CL | where TimeGenerated > ago(30d)) on $left.ClientIP == $right.LeaseIP
| take 20
```

**Example 3 · NetScaler and DHCP**

```kusto
Netscaler_Logs_CL
| where TimeGenerated > ago(30d) and isnotempty(ClientIP)
| join kind = inner (Infoblox_DHCP_CL | where TimeGenerated > ago(30d)) on $left.ClientIP == $right.LeaseIP
| take 20
```

#### 7.3 Cold data: the same applies to union and let

*02-KQL.pptx · slides 38–39* — Every branch of a union or let has a time filter.

**Example 1 · union with a filter per table**

```kusto
union (Palo_FW_CL | where TimeGenerated > ago(30d) | project TimeGenerated, IP = SrcIP),
      (Infoblox_DNS_CL | where TimeGenerated > ago(30d) | project TimeGenerated, IP = ClientIP)
| summarize count() by IP
| top 10 by count_
```

**Example 2 · let with a time filter inside**

```kusto
let RecentDhcp = Infoblox_DHCP_CL
    | where TimeGenerated > ago(30d)
    | summarize Events = count() by LeaseIP;
RecentDhcp
| top 10 by Events
```

**Example 3 · let used twice, each scoped**

```kusto
let RecentFw = Palo_FW_CL | where TimeGenerated > ago(30d);
let RecentDns = Infoblox_DNS_CL | where TimeGenerated > ago(30d);
RecentFw
| summarize Fw = count() by SrcIP
| join (RecentDns | summarize Dns = count() by SrcIP = ClientIP) on SrcIP
| take 20
```

#### 7.4 Query optimization: start with filtering by time

*02-KQL.pptx · slide 40* — Keep hot cache size in mind.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| where TimeGenerated > ago(30d)
| where Action == "deny"
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| where TimeGenerated > ago(30d)
| where EventType == "QueryFailure"
```

**Example 3 · NetScaler**

```kusto
Netscaler_Logs_CL
| where TimeGenerated > ago(30d)
| where Module == "APPFW"
```

#### 7.5 Query optimization: filter fast, the less data for the next step the better

*02-KQL.pptx · slide 41* — Filter before you count or summarize.

**Example 1 · has, then count**

```kusto
Infoblox_DNS_CL
| where DnsQuery has "signalfx"
| count
```

**Example 2 · startswith, then count**

```kusto
Infoblox_DHCP_CL
| where ClientHostname startswith "WP2"
| count
```

**Example 3 · Equality, then count**

```kusto
Palo_FW_CL
| where Action == "reset-both"
| count
```

#### 7.6 Query optimization: use efficient operators

*02-KQL.pptx · slide 42* — Equality first, then has / startswith; avoid contains and endswith unless needed. The full comparison per operator is in section 2 (slide 63).

**Example 1 · Equality (best)**

```kusto
Infoblox_DNS_CL
| where DnsQuery == "wpad.westjet.priv"
| count
```

**Example 2 · has / startswith**

```kusto
Infoblox_DNS_CL
| where DnsQuery has "wpad"
| count
```

**Example 3 · contains (avoid unless really needed)**

```kusto
Infoblox_DNS_CL
| where DnsQuery contains "wpad"
| count
```

#### 7.7 Query optimization: use native rather than calculated columns

*02-KQL.pptx · slide 43* — Filter on the original column instead of an extended one.

**Example 1 · Native column**

```kusto
Infoblox_DNS_CL
| where DnsQuery has "microsoft"
| count
```

**Example 2 · Extreme but telling: calculated column then filter**

```kusto
Infoblox_DNS_CL
| extend NewCol = strcat(DnsQuery, "x")
| where NewCol has "microsoft"
| count
```

**Example 3 · Copy of the column then filter**

```kusto
Infoblox_DNS_CL
| extend NewCol = DnsQuery
| where NewCol has "microsoft"
| count
```

#### 7.8 Query optimization: =~ instead of tolower() ==

*02-KQL.pptx · slide 43* — Case-insensitive comparison without calculating a column.

**Example 1 · More typical: =~**

```kusto
Palo_FW_CL
| where Action =~ "DENY"
| count
```

**Example 2 · Slower: tolower() ==**

```kusto
Palo_FW_CL
| where tolower(Action) == "deny"
| count
```

**Example 3 · =~ on DNS**

```kusto
Infoblox_DNS_CL
| where QueryType =~ "aaaa"
| count
```

#### 7.9 Query optimization: filter every table, explicitly

*02-KQL.pptx · slide 44* — Put the smaller, filtered table on the left side of a join.

**Example 1 · Filter left, then join a filtered right side**

```kusto
Palo_FW_CL
| where TimeGenerated > ago(30d) and Action == "deny"
| join kind = inner (Infoblox_DNS_CL | where TimeGenerated > ago(30d)) on $left.SrcIP == $right.ClientIP
| take 20
```

**Example 2 · Smaller table on the left**

```kusto
Infoblox_DNS_CL
| where TimeGenerated > ago(30d) and ClientIP == "10.1.132.14"
| join kind = inner (Palo_FW_CL | where TimeGenerated > ago(30d)) on $left.ClientIP == $right.SrcIP
| take 20
```

**Example 3 · Filter inside the subquery**

```kusto
Infoblox_DHCP_CL
| where TimeGenerated > ago(30d) and EventType == "DHCPACK"
| join kind = inner (Netscaler_Logs_CL | where TimeGenerated > ago(30d) and isnotempty(ClientIP)) on $left.LeaseIP == $right.ClientIP
| take 20
```

#### 7.10 Checklist, Filter: filter early

*02-KQL.pptx · slide 45* — Start with a time filter and filter early.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| where TimeGenerated > ago(30d)
| where Action == "deny"
| summarize count() by SrcIP
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| where TimeGenerated > ago(30d)
| where EventType == "Query"
| summarize count() by ClientIP
```

**Example 3 · NetScaler**

```kusto
Netscaler_Logs_CL
| where TimeGenerated > ago(30d)
| where Module == "SSLVPN"
| summarize count() by ClientIP
```

#### 7.11 Checklist, Reduce: summarize early

*02-KQL.pptx · slide 45* — Aggregate before you join or sort.

**Example 1 · Firewall**

```kusto
Palo_FW_CL
| summarize Sessions = count() by SrcIP
| join kind = inner (Infoblox_DNS_CL | summarize Queries = count() by SrcIP = ClientIP) on SrcIP
| take 20
```

**Example 2 · DNS**

```kusto
Infoblox_DNS_CL
| summarize Queries = count() by ClientIP
| top 10 by Queries
```

**Example 3 · DHCP**

```kusto
Infoblox_DHCP_CL
| summarize Events = count() by LeaseIP
| top 10 by Events
```

#### 7.12 Checklist, Reduce: project explicitly

*02-KQL.pptx · slide 45* — Keep only the columns you need (project-away is an alternative).

**Example 1 · project**

```kusto
Palo_FW_CL
| project TimeGenerated, SrcIP, DestIP, Action
| take 10
```

**Example 2 · project-away**

```kusto
Infoblox_DNS_CL
| project-away RawMessage, SyslogSenderIP, ZoneName, KeyName, SOASerial
| take 10
```

**Example 3 · project before a join**

```kusto
Infoblox_DHCP_CL
| project LeaseIP, ClientHostname
| join kind = inner (Netscaler_Logs_CL | project ClientIP, Module) on $left.LeaseIP == $right.ClientIP
| take 20
```

#### 7.13 Checklist, Multiple tables: use the smaller table on the join left side

*02-KQL.pptx · slide 45* — The left side should be the smaller one.

**Example 1 · Small filtered DNS client on the left**

```kusto
Infoblox_DNS_CL
| where ClientIP == "10.1.132.14"
| join kind = inner (Palo_FW_CL) on $left.ClientIP == $right.SrcIP
| project ClientIP, DnsQuery, DestIP, Action
| take 20
```

**Example 2 · Abandoned leases on the left**

```kusto
Infoblox_DHCP_CL
| where EventType == "AbandonedLease"
| join kind = inner (Infoblox_DNS_CL) on $left.LeaseIP == $right.ClientIP
| project LeaseIP, DnsQuery
| take 20
```

**Example 3 · TCP events on the left**

```kusto
Netscaler_Logs_CL
| where Module == "TCP" and isnotempty(SrcIP)
| join kind = inner (Palo_FW_CL) on SrcIP
| project SrcIP, EventType, DestIP
| take 20
```

#### 7.14 Checklist, Multiple tables: materialize

*02-KQL.pptx · slide 45* — Cache a sub-result that is used several times.

**Example 1 · Firewall**

```kusto
let Sessions = materialize(Palo_FW_CL | summarize Count = count() by SrcIP);
Sessions
| top 5 by Count
| union (Sessions | where Count == 1 | take 5)
```

**Example 2 · DNS**

```kusto
let Queries = materialize(Infoblox_DNS_CL | where EventType == "Query" | summarize Count = count() by ClientIP);
Queries
| top 5 by Count
| union (Queries | where Count == 1 | take 5)
```

**Example 3 · DHCP**

```kusto
let Events = materialize(Infoblox_DHCP_CL | summarize Count = count() by LeaseIP);
Events
| top 5 by Count
| union (Events | where Count == 1 | take 5)
```

#### 7.15 Checklist, Parse: use split, parse or extract_all instead of multiple extracts

*02-KQL.pptx · slide 45* — One parse beats several extracts.

**Example 1 · parse once**

```kusto
Netscaler_Logs_CL
| where Payload has "errno"
| parse Payload with * "errno: " ErrNo " key: " Key
| project TimeGenerated, ErrNo, Key
```

**Example 2 · split once**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| extend Labels = split(DnsQuery, ".")
| extend First = tostring(Labels[0]), Last = tostring(Labels[-1])
| project DnsQuery, First, Last
```

**Example 3 · extract_all once**

```kusto
Palo_FW_CL
| extend Octets = extract_all("([0-9]+)", SrcIP)
| project SrcIP, Octets
| take 10
```

