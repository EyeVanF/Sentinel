# Foundational KQL - Network Workshop

Instructor copy/paste companion for **Foundational KQL for Network Operations**.
Sections follow the PowerPoint in the **same order**; each heading shows its slide number.
Every query below is used on a slide, in an exercise or solution, or in a take-home library slide.

## Before you start

**Tables used:** `Palo_FW_CL` (firewall), `Infoblox_DNS_CL` (DNS), `Infoblox_DHCP_CL` (DHCP), `Netscaler_Logs_CL` (NetScaler).

**Column names** come from exports of the four tables (see the schema appendix slide). Always confirm in the live workspace:

```kusto
Palo_FW_CL
| getschema
```

**Time range.** Examples use relative time such as `ago(1h)` and `ago(24h)`. The lab sample is a **static dataset from 2026-11-16 (UTC)**,
so relative filters may return nothing. In that case, replace the `ago(...)` filter with an exact window:

```kusto
| where TimeGenerated between (datetime(2026-11-16 00:00:00) .. datetime(2026-11-17 00:00:00))
```

**Bin sizes.** The lab sample covers only seconds to minutes, so time-chart examples use `5s`, `10s` and `1m`.
On live data use `5m`, `15m` or `1h`.

**Instructor validation flags** are listed in the Appendix of the deck (slide "A2 · Instructor validation flags") and marked in the speaker notes.

**Pacing guide** (slides tagged OPTIONAL or STRETCH can be skipped or demoed if you run behind):

| Block | Time | Core | Build steps | Exercises | Optional / stretch |
|---|---|---|---|---|---|
| Intro | 0:00 – 0:15 | 5 | 0 | 0 (+0 solutions) | 0 optional, 0 stretch |
| Module 1 | 0:15 – 0:45 | 10 | 0 | 1 (+1 solutions) | 0 optional, 0 stretch |
| Module 2 | 0:45 – 1:30 | 6 | 5 | 2 (+2 solutions) | 0 optional, 0 stretch |
| Module 3 | 1:45 – 2:30 | 9 | 5 | 2 (+3 solutions) | 1 optional, 1 stretch |
| Modules 4 + 5 | 3:30 – 4:15 | 13 | 5 | 2 (+5 solutions) | 7 optional, 3 stretch |
| Module 6 | 4:30 – 5:00 | 14 | 0 | 0 (+0 solutions) | 4 optional, 0 stretch |

---

## 1. Log Analytics fundamentals & data exploration

### 1.1 Discover what data exists  
*(slide 15)*

**1.  Count records in every table**

```kusto
search *
| summarize count() by $table
| order by count_ desc
```

**2.  List only the custom (_CL) tables**

```kusto
union withsource=TableName *_CL
| summarize Records=count() by TableName
```

### 1.2 What do we have? Our four tables at a glance  
*(slide 16)*

```kusto
union withsource=TableName
      Palo_FW_CL, Infoblox_DHCP_CL, Infoblox_DNS_CL, Netscaler_Logs_CL
| summarize Records=count(),
            FirstEvent=min(TimeGenerated),
            LastEvent=max(TimeGenerated) by TableName
```

### 1.3 Inspect before you assume  
*(slide 17)*

**Look at sample records**

```kusto
Palo_FW_CL
| take 10
```

**List every column and its data type**

```kusto
Palo_FW_CL
| getschema
```

### 1.4 Exercise 1: Explore the four tables  
*(slide 18)*

**Objective:** Look at the other three tables and note the columns you will use most.  
**Question:** Which column holds the client IP in DNS? Which holds the hostname in DHCP? Which column tells you the type of event in NetScaler?  
**Hints:** Use take 10 on each table; Scroll right to see every column; Run getschema on one table; Make a short list of key columns

### 1.5 Solution 1: Explore the four tables  
*(slide 19)*

```kusto
Infoblox_DNS_CL
| take 10

Infoblox_DHCP_CL
| take 10

Netscaler_Logs_CL
| take 10
```


## 2. KQL fundamentals & basic operators

### 2.1 Your first query  
*(slide 22)*

```kusto
// A comment starts with two slashes
Palo_FW_CL
| take 10        // keep only 10 rows
```

### 2.2 take and limit: peek at the data  
*(slide 23)*

**Firewall: ten rows**

```kusto
Palo_FW_CL
| take 10
```

**DHCP: five rows using limit**

```kusto
Infoblox_DHCP_CL
| limit 5
```

### 2.3 project and project-away: choose your columns  
*(slide 24)*

**project: keep and rename**

```kusto
Palo_FW_CL
| take 10
| project Time=TimeGenerated, Source=SrcIP, Destination=DestIP, Port=DestPort, Action
```

**project-away: drop noise**

```kusto
Palo_FW_CL
| take 10
| project-away CefFields, CefHeader, ActionFlags, SyslogSenderIP
```

### 2.4 where: keep only the rows you want  
*(slide 25)*

**Denied firewall events**

```kusto
Palo_FW_CL
| where Action == "deny"
| project TimeGenerated, SrcIP, DestIP, DestPort, Action
```

**Traffic to port 443**

```kusto
Palo_FW_CL
| where DestPort == 443
| project TimeGenerated, SrcIP, DestIP, DestPort, App
```

### 2.5 sort and top: order your results  
*(slide 26)*

**Newest first**

```kusto
Infoblox_DNS_CL
| sort by TimeGenerated desc
| project TimeGenerated, ClientIP, DnsQuery
| take 10
```

**Biggest transfers**

```kusto
Palo_FW_CL
| top 10 by BytesOut
| project TimeGenerated, SrcIP, DestIP, DestPort, BytesOut
```

### 2.6 Build it: a readable denied-traffic list — step 1/5  
*(slide 27)*

```kusto
Palo_FW_CL
```

### 2.7 Build it: a readable denied-traffic list — step 2/5  
*(slide 28)*

```kusto
Palo_FW_CL
| where Action == "deny"
```

### 2.8 Build it: a readable denied-traffic list — step 3/5  
*(slide 29)*

```kusto
Palo_FW_CL
| where Action == "deny"
| project TimeGenerated, SrcIP, DestIP, DestPort, App, Rule
```

### 2.9 Build it: a readable denied-traffic list — step 4/5  
*(slide 30)*

```kusto
Palo_FW_CL
| where Action == "deny"
| project TimeGenerated, SrcIP, DestIP, DestPort, App, Rule
| sort by TimeGenerated desc
```

### 2.10 Build it: a readable denied-traffic list — step 5/5  
*(slide 31)*

```kusto
Palo_FW_CL
| where Action == "deny"
| project TimeGenerated, SrcIP, DestIP, DestPort, App, Rule
| sort by TimeGenerated desc
| take 20
```

### 2.11 Exercise 2: A readable DNS view  
*(slide 32)*

**Objective:** Show the 15 most recent DNS events with only four useful columns.  
**Question:** Your colleague asks: 'What was the DNS server asked most recently?' Show time, client, name and record type.  
**Hints:** Start from Infoblox_DNS_CL; sort by TimeGenerated desc; project four columns; take 15

### 2.12 Solution 2: A readable DNS view  
*(slide 33)*

```kusto
Infoblox_DNS_CL
| sort by TimeGenerated desc
| project TimeGenerated, ClientIP, DnsQuery, QueryType
| take 15
```

### 2.13 Exercise 3: Biggest firewall transfers  
*(slide 34)*

**Objective:** Find the five sessions with the most bytes sent out, and show who, where and which app.  
**Question:** Capacity planning asks: 'Which five firewall sessions moved the most outbound data?'  
**Hints:** Use top 5 by BytesOut; Add project for readability; Include SrcIP, DestIP, DestPort, App, BytesOut

### 2.14 Solution 3: Biggest firewall transfers  
*(slide 35)*

```kusto
Palo_FW_CL
| top 5 by BytesOut
| project TimeGenerated, SrcIP, DestIP, DestPort, App, BytesOut
```


## 3. Filtering & investigating network data

### 3.1 Comparison operators  
*(slide 37)*

**Large transfers (numeric comparison)**

```kusto
Palo_FW_CL
| where BytesOut > 1000000
| project TimeGenerated, SrcIP, DestIP, DestPort, BytesOut
```

**Everything except DNS traffic (not equal)**

```kusto
Palo_FW_CL
| where App != "dns-base"
| project TimeGenerated, SrcIP, DestIP, DestPort, App
```

**Case-insensitive match**

```kusto
Palo_FW_CL
| where Action =~ "DENY"
| project TimeGenerated, SrcIP, DestIP, Action
```

### 3.2 has vs. contains: see the difference  
*(slide 39)*

**contains: any substring**

```kusto
Infoblox_DNS_CL
| where DnsQuery contains "microsoft"
| summarize Matches=count()
```

**has: a whole term only**

```kusto
Infoblox_DNS_CL
| where DnsQuery has "microsoft"
| summarize Matches=count()
```

### 3.3 startswith, endswith and case-insensitive match  
*(slide 40)*

**Firewall sources in a range of the 10.158.x.x address space**

```kusto
Palo_FW_CL
| where SrcIP startswith "10.158."
| project TimeGenerated, SrcIP, DestIP, DestPort, Action
```

**DNS names that end with a domain suffix**

```kusto
Infoblox_DNS_CL
| where DnsQuery endswith ".microsoft.com"
| project TimeGenerated, ClientIP, DnsQuery, QueryType
```

### 3.4 in, !in and between  
*(slide 41)*

**in: any value from a list**

```kusto
Palo_FW_CL
| where Action in ("deny", "reset-both", "block-url")
| project TimeGenerated, SrcIP, DestIP, DestPort, Action
```

**!in: exclude a list**

```kusto
Palo_FW_CL
| where App !in ("dns-base", "ssl")
| project TimeGenerated, SrcIP, DestIP, DestPort, App
```

**between: a numeric range (inclusive)**

```kusto
Palo_FW_CL
| where DestPort between (1024 .. 65535)
| project TimeGenerated, SrcIP, DestIP, DestPort, App
```

### 3.5 Combine conditions: and, or, not  
*(slide 42)*

**and: both conditions must be true**

```kusto
Palo_FW_CL
| where Action != "allow" and DestPort == 443
| project TimeGenerated, SrcIP, DestIP, DestPort, Action
```

**or inside parentheses: either direction of a flow**

```kusto
Palo_FW_CL
| where (SrcIP == "10.158.8.10" or DestIP == "10.158.8.10") and Action == "allow"
| project TimeGenerated, SrcIP, DestIP, DestPort, App
```

**not: exclude a condition**

```kusto
Palo_FW_CL
| where not(App in ("dns-base", "ssl"))
| project TimeGenerated, SrcIP, DestIP, DestPort, App
```

### 3.6 Filter by time  
*(slide 43)*

**Relative: the last hour / the last 24 hours**

```kusto
Palo_FW_CL
| where TimeGenerated > ago(1h)
// also: ago(30m), ago(24h), ago(7d)
```

**Exact window**

```kusto
Palo_FW_CL
| where TimeGenerated between (datetime(2026-11-16 20:02:00) .. datetime(2026-11-16 20:02:15))
| project TimeGenerated, SrcIP, DestIP, Action
```

### 3.7 Empty values: isempty and isnotempty  
*(slide 44)*

```kusto
Palo_FW_CL
| where isnotempty(Url)
| project TimeGenerated, SrcIP, Url, UrlCategory, Action
```

### 3.8 Build it: all traffic for one IP address — step 1/5  
*(slide 45)*

```kusto
Palo_FW_CL
```

### 3.9 Build it: all traffic for one IP address — step 2/5  
*(slide 46)*

```kusto
Palo_FW_CL
| where TimeGenerated > ago(24h)
```

### 3.10 Build it: all traffic for one IP address — step 3/5  
*(slide 47)*

```kusto
Palo_FW_CL
| where TimeGenerated > ago(24h)
| where SrcIP == "10.158.8.10"
```

### 3.11 Build it: all traffic for one IP address — step 4/5  
*(slide 48)*

```kusto
Palo_FW_CL
| where TimeGenerated > ago(24h)
| where SrcIP == "10.158.8.10" or DestIP == "10.158.8.10"
```

### 3.12 Build it: all traffic for one IP address — step 5/5  
*(slide 49)*

```kusto
Palo_FW_CL
| where TimeGenerated > ago(24h)
| where SrcIP == "10.158.8.10" or DestIP == "10.158.8.10"
| project TimeGenerated, SrcIP, DestIP, DestPort, App, Action
```

### 3.13 Recipes: firewall  
*(slide 50)*

**Recent activity**

```kusto
Palo_FW_CL
| where TimeGenerated > ago(1h)
| project TimeGenerated, SrcIP, DestIP, DestPort, App, Action
```

**Blocked traffic in the last 24 hours**

```kusto
Palo_FW_CL
| where TimeGenerated > ago(24h)
| where Action in ("deny", "reset-both", "block-url")
| project TimeGenerated, SrcIP, DestIP, DestPort, App, Rule, Action
```

**Everything going to one destination**

```kusto
Palo_FW_CL
| where DestIP == "188.172.213.89"
| project TimeGenerated, SrcIP, DestIP, DestPort, App, Action
```

### 3.14 Recipes: DNS, DHCP and NetScaler  
*(slide 51)*

**DNS: queries for a domain**

```kusto
Infoblox_DNS_CL
| where DnsQuery has "microsoft"
| project TimeGenerated, ClientIP, DnsQuery, QueryType
```

**DHCP: activity for one IP**

```kusto
Infoblox_DHCP_CL
| where LeaseIP == "10.216.132.166"
| project TimeGenerated, EventType, LeaseIP, ClientMAC, ClientHostname
```

**NetScaler: entries containing a value**

```kusto
Netscaler_Logs_CL
| where Payload contains "nFactor"
| project TimeGenerated, DeviceName, Module, EventType, Payload
```

### 3.15 Exercise 4: Find blocked traffic  
*(slide 52)*

**Objective:** List blocked firewall events from the last 24 hours with who, where, and which rule.  
**Question:** The security team asks: 'What did the firewall block today, and which rule blocked it?'  
**Hints:** Filter Action with in (...); Values: deny, reset-both, block-url; Add a time filter on TimeGenerated; project TimeGenerated, SrcIP, DestIP, DestPort, App, Rule, Action

### 3.16 Solution 4: Find blocked traffic  
*(slide 53)*

```kusto
Palo_FW_CL
| where TimeGenerated > ago(24h)
| where Action in ("deny", "reset-both", "block-url")
| project TimeGenerated, SrcIP, DestIP, DestPort, App, Rule, Action
| sort by TimeGenerated desc
```

### 3.17 Exercise 5: What does DHCP know about this host?  
*(slide 54)*

**Objective:** Show every DHCP event for one IP address, newest first.  
**Question:** A user says their workstation is 10.216.132.166 and reports intermittent issues. What does DHCP show for that IP?  
**Hints:** Start from Infoblox_DHCP_CL; Filter on LeaseIP; Show EventType, ClientMAC and ClientHostname; Newest first

### 3.18 Solution 5: What does DHCP know about this host?  
*(slide 55)*

```kusto
Infoblox_DHCP_CL
| where LeaseIP == "10.216.132.166"
| project TimeGenerated, EventType, LeaseIP, ClientMAC, ClientHostname
| sort by TimeGenerated desc
```

### 3.19 Exercise 6: Microsoft DNS lookups from one range  
*(slide 56)*

**Objective:** Find DNS queries for names ending in microsoft.com made by clients in 10.216.x.x.  
**Question:** Which clients in the 10.216.x.x range looked up Microsoft names?  
**Hints:** Only "Query" events: EventType == "Query"; endswith for the domain; startswith for the IP range; Combine with and

### 3.20 Solution 6: Microsoft DNS lookups from one range  
*(slide 57)*

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| where DnsQuery endswith "microsoft.com"
| where ClientIP startswith "10.216."
| project TimeGenerated, ClientIP, DnsQuery, QueryType
```


## 4. Summarizing network activity

### 4.1 count vs. summarize count()  
*(slide 59)*

**Total records**

```kusto
Palo_FW_CL
| count
```

**Same answer, general form**

```kusto
Palo_FW_CL
| summarize count()
```

**Count per group**

```kusto
Palo_FW_CL
| summarize count() by Action
```

### 4.2 countif and distinct  
*(slide 60)*

**countif: blocked vs total in one result**

```kusto
Palo_FW_CL
| summarize Total=count(),
            Blocked=countif(Action in ("deny", "reset-both", "block-url"))
```

**distinct: what values exist?**

```kusto
Palo_FW_CL
| distinct Action
```

### 4.3 Several answers in one query  
*(slide 62)*

```kusto
Palo_FW_CL
| summarize Connections = count(),
            UniqueSources = dcount(SrcIP),
            TotalBytesOut = sum(BytesOut),
            AvgBytesOut = avg(BytesOut),
            LastSeen = max(TimeGenerated)
```

### 4.4 Group by one or more columns  
*(slide 63)*

**By one column**

```kusto
Palo_FW_CL
| summarize Connections=count() by SrcZone
```

**By two columns**

```kusto
Palo_FW_CL
| summarize Connections=count() by SrcZone, DestZone
| sort by Connections desc
```

### 4.5 Build it: who does this host talk to? — step 1/5  
*(slide 64)*

```kusto
Palo_FW_CL
```

### 4.6 Build it: who does this host talk to? — step 2/5  
*(slide 65)*

```kusto
Palo_FW_CL
| where TimeGenerated > ago(24h)
```

### 4.7 Build it: who does this host talk to? — step 3/5  
*(slide 66)*

```kusto
Palo_FW_CL
| where TimeGenerated > ago(24h)
| where SrcIP == "10.158.8.10"
```

### 4.8 Build it: who does this host talk to? — step 4/5  
*(slide 67)*

```kusto
Palo_FW_CL
| where TimeGenerated > ago(24h)
| where SrcIP == "10.158.8.10"
| summarize Connections=count() by DestIP
```

### 4.9 Build it: who does this host talk to? — step 5/5  
*(slide 68)*

```kusto
Palo_FW_CL
| where TimeGenerated > ago(24h)
| where SrcIP == "10.158.8.10"
| summarize Connections=count() by DestIP
| top 10 by Connections
```

### 4.10 Exercise 7: Top talkers  
*(slide 69)*

**Objective:** Find the 10 most active source IP addresses during the last 24 hours.  
**Question:** Which sources generate the most firewall sessions?  
**Hints:** Start from Palo_FW_CL and filter by time; summarize count() by SrcIP; Name the count Connections; top 10 by Connections

### 4.11 Solution 7: Top talkers  
*(slide 70)*

```kusto
Palo_FW_CL
| where TimeGenerated > ago(24h)
| summarize Connections=count() by SrcIP
| top 10 by Connections
```

### 4.12 Exercise 8: Which rule blocks the most?  
*(slide 71)*

**Objective:** Find which firewall rules and applications account for the most blocked events.  
**Question:** Security wants to tune policy: which rule/application combinations generate the most blocks?  
**Hints:** Filter the blocking actions with in; summarize count() by Rule, App; Sort or top by the count

### 4.13 Solution 8: Which rule blocks the most?  
*(slide 72)*

```kusto
Palo_FW_CL
| where Action in ("deny", "reset-both", "block-url")
| summarize Blocked=count() by Rule, App
| top 10 by Blocked
```

### 4.14 Exercise 9: Most queried domains  
*(slide 73)*

**Objective:** Find the 10 most frequently queried DNS names, with how many different clients asked.  
**Question:** Which DNS names are asked the most, and by how many different clients?  
**Hints:** Keep EventType == "Query"; Use count() and dcount(ClientIP); Group by DnsQuery; Order by the number of queries

### 4.15 Solution 9: Most queried domains  
*(slide 74)*

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| summarize Queries=count(), Clients=dcount(ClientIP) by DnsQuery
| top 10 by Queries
```

### 4.16 Group by time: bin()  
*(slide 75)*

**Syntax: events per 5 minutes (typical for live data)**

```kusto
Palo_FW_CL
| summarize Events=count() by bin(TimeGenerated, 5m)
| sort by TimeGenerated asc
```

**Lab sample spans seconds, so use a smaller bucket**

```kusto
Palo_FW_CL
| summarize Events=count() by bin(TimeGenerated, 10s)
| sort by TimeGenerated asc
```

### 4.17 Events over time: DNS, DHCP and NetScaler  
*(slide 76)*

**DNS: queries per 5 seconds**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| summarize Queries=count() by bin(TimeGenerated, 5s)
| sort by TimeGenerated asc
```

**DHCP: events per minute**

```kusto
Infoblox_DHCP_CL
| summarize Events=count() by bin(TimeGenerated, 1m)
| sort by TimeGenerated asc
```

**NetScaler: events per minute**

```kusto
Netscaler_Logs_CL
| summarize Events=count() by bin(TimeGenerated, 1m)
| sort by TimeGenerated asc
```

### 4.18 See it: a simple time chart  
*(slide 77)*

```kusto
Palo_FW_CL
| summarize Events=count() by bin(TimeGenerated, 10s)
| render timechart
```

### 4.19 Recipes: firewall summaries  
*(slide 78)*

**Most common destination IPs**

```kusto
Palo_FW_CL
| summarize Connections=count() by DestIP
| top 10 by Connections
```

**Destinations contacted by the most different clients**

```kusto
Palo_FW_CL
| summarize Clients=dcount(SrcIP) by DestIP
| top 10 by Clients
```

**Most active destination ports**

```kusto
Palo_FW_CL
| where isnotempty(DestPort)
| summarize Connections=count() by DestPort, Protocol
| top 10 by Connections
```

### 4.20 Recipes: DHCP, DNS and NetScaler summaries  
*(slide 79)*

**DHCP: most active clients**

```kusto
Infoblox_DHCP_CL
| where isnotempty(ClientHostname)
| summarize Events=count() by ClientHostname
| top 10 by Events
```

**DNS: query types**

```kusto
Infoblox_DNS_CL
| summarize Queries=count() by QueryType
| sort by Queries desc
```

**NetScaler: events by category**

```kusto
Netscaler_Logs_CL
| summarize Events=count() by Module, EventType
| top 10 by Events
```


## 5. Functions useful for network teams

### 5.1 extend: create a calculated column  
*(slide 81)*

```kusto
Palo_FW_CL
| extend TotalBytes = BytesIn + BytesOut
| project TimeGenerated, SrcIP, DestIP, DestPort, TotalBytes
| top 10 by TotalBytes
```

### 5.2 Date and time: ago(), now() and event age  
*(slide 83)*

**Show the values**

```kusto
print Now=now(), OneHourAgo=ago(1h), OneDayAgo=ago(1d)
```

**How many hours ago did each event occur?**

```kusto
Palo_FW_CL
| extend AgeHours = round((now() - TimeGenerated) / 1h, 1)
| project TimeGenerated, AgeHours, SrcIP, DestIP
| take 5
```

### 5.3 Text functions: tolower, toupper, strlen  
*(slide 84)*

**toupper: normalize MAC addresses**

```kusto
Infoblox_DHCP_CL
| where isnotempty(ClientMAC)
| extend MAC = toupper(ClientMAC)
| project TimeGenerated, ClientHostname, MAC
| take 10
```

**strlen: spot unusually long DNS names**

```kusto
Infoblox_DNS_CL
| where EventType == "Query"
| extend NameLength = strlen(DnsQuery)
| top 10 by NameLength
| project TimeGenerated, ClientIP, NameLength, DnsQuery
```

### 5.4 Text functions: strcat, split, replace_string  
*(slide 85)*

**strcat: build a readable flow**

```kusto
Palo_FW_CL
| where isnotempty(DestPort)
| extend Flow = strcat(SrcIP, " -> ", DestIP, ":", DestPort)
| project TimeGenerated, Flow, Action
```

**split: pull the last part of a DNS name**

```kusto
Infoblox_DNS_CL
| extend TopLevelDomain = tostring(split(DnsQuery, ".")[-1])
| summarize Queries=count() by TopLevelDomain
```

**replace_string: strip a suffix**

```kusto
Infoblox_DNS_CL
| where DnsQuery endswith ".microsoft.com"
| extend ShortName = replace_string(DnsQuery, ".microsoft.com", "")
```

### 5.5 Conversion functions: tostring and toint  
*(slide 86)*

**tostring: match a port by its digits**

```kusto
Palo_FW_CL
| where tostring(DestPort) startswith "44"
| project TimeGenerated, SrcIP, DestIP, DestPort
```

**toint: turn the seconds part of a duration into a number**

```kusto
Netscaler_Logs_CL
| where isnotempty(Duration)
| extend Seconds = toint(split(Duration, ":")[2])
| project TimeGenerated, Module, Duration, Seconds
| take 10
```

### 5.6 Conditional functions: iff and case  
*(slide 87)*

**iff: blocked vs permitted**

```kusto
Palo_FW_CL
| extend Result = iff(Action in ("deny", "reset-both", "block-url"), "Blocked", "Permitted")
| summarize Events=count() by Result
```

**case: the DHCP exchange in order (DORA)**

```kusto
Infoblox_DHCP_CL
| extend Phase = case(EventType == "DHCPDISCOVER", "1-Discover",
                      EventType == "DHCPOFFER", "2-Offer",
                      EventType == "DHCPREQUEST", "3-Request",
                      EventType == "DHCPACK", "4-Acknowledge",
                      "Other")
| summarize Events=count() by Phase
| sort by Phase asc
```

### 5.7 Empty-value checks as a column: isempty and isnotempty  
*(slide 88)*

```kusto
Infoblox_DHCP_CL
| extend HasHostname = isnotempty(ClientHostname)
| summarize Events=count() by HasHostname
```

### 5.8 IPv4 functions: subnet and private-address checks  
*(slide 89)*

**ipv4_is_match: is the source inside a CIDR subnet?**

```kusto
Palo_FW_CL
| where ipv4_is_match(SrcIP, "10.158.0.0/16")
| project TimeGenerated, SrcIP, DestIP, DestPort, Action
```

**ipv4_is_private: internal or external destination?**

```kusto
Palo_FW_CL
| where isnotempty(DestIP)
| extend DestType = iff(ipv4_is_private(DestIP), "Internal", "External")
| summarize Connections=count() by DestType
```

### 5.9 IPv4 functions: validate and compare  
*(slide 90)*

**parse_ipv4: does the value parse as IPv4?**

```kusto
Netscaler_Logs_CL
| extend ValidClientIP = isnotnull(parse_ipv4(ClientIP))
| summarize Events=count() by ValidClientIP
```

**ipv4_compare: addresses between .1 and .50**

```kusto
Palo_FW_CL
| where ipv4_compare(SrcIP, "10.158.8.1") >= 0 and ipv4_compare(SrcIP, "10.158.8.50") <= 0
| project TimeGenerated, SrcIP, DestIP, DestPort, Action
```

### 5.10 Exercise 10: Classify firewall traffic by service  
*(slide 91)*

**Objective:** Label each session as DNS, HTTPS, HTTP, LDAP or Other by port, then count each label.  
**Question:** Management asks: 'What kinds of traffic cross this firewall?'  
**Hints:** Create a column with case(); Compare DestPort to 53, 443, 80 and 389; Finish with a default label: Other; summarize count() by the new column

### 5.11 Solution 10: Classify firewall traffic by service  
*(slide 92)*

```kusto
Palo_FW_CL
| extend Service = case(DestPort == 53, "DNS",
                      DestPort == 443, "HTTPS",
                      DestPort == 80, "HTTP",
                      DestPort == 389, "LDAP",
                      "Other")
| summarize Sessions=count() by Service
| sort by Sessions desc
```

### 5.12 Exercise 11: Blocked traffic leaving the network  
*(slide 93)*

**Objective:** Find the 10 external destinations that had the most blocked sessions.  
**Question:** Which Internet destinations is the firewall blocking the most?  
**Hints:** Filter blocking actions with in (...); Remove empty DestIP values; Keep destinations where ipv4_is_private is false; summarize count() by DestIP, then top 10

### 5.13 Solution 11: Blocked traffic leaving the network  
*(slide 94)*

```kusto
Palo_FW_CL
| where Action in ("deny", "reset-both", "block-url")
| where isnotempty(DestIP)
| where not(ipv4_is_private(DestIP))
| summarize Blocked=count() by DestIP
| top 10 by Blocked
```


## 6. Troubleshooting scenarios, recap & next steps

### 6.1 Scenario A · Step 1: find the IP address (DHCP)  
*(slide 98)*

```kusto
Infoblox_DHCP_CL
| where ClientHostname == "WP2MQ4370P1Z"
| project TimeGenerated, EventType, LeaseIP, ClientMAC, LeaseState, DHCPServerIP
| sort by TimeGenerated desc
```

### 6.2 Scenario A · Step 2: what did it ask DNS?  
*(slide 99)*

```kusto
Infoblox_DNS_CL
| where ClientIP == "10.216.132.166"
| project TimeGenerated, EventType, DnsQuery, QueryType, DNSServerIP
| sort by TimeGenerated desc
```

### 6.3 Scenario A · Step 3: was traffic allowed? (firewall)  
*(slide 100)*

```kusto
Palo_FW_CL
| where SrcIP == "10.216.132.166" or DestIP == "10.216.132.166"
| project TimeGenerated, SrcIP, DestIP, DestPort, App, Rule, Action
| sort by TimeGenerated desc
```

### 6.4 Scenario A · Step 4: was there a NetScaler session?  
*(slide 101)*

```kusto
Netscaler_Logs_CL
| where ClientIP == "10.216.132.166" or SrcIP == "10.216.132.166" or NatIP == "10.216.132.166"
| project TimeGenerated, DeviceName, Module, EventType, ClientIP, SrcIP
```

### 6.5 Scenario B · Who is trying to use blocked applications?  
*(slide 103)*

**Step 1: blocked rule and application combinations**

```kusto
Palo_FW_CL
| where Action in ("deny", "reset-both", "block-url")
| summarize Blocked=count() by Rule, App
| top 5 by Blocked
```

**Step 2: which sources attempted the top blocked application?**

```kusto
Palo_FW_CL
| where App == "teamviewer-base"
| summarize Attempts=count(), Blocked=countif(Action != "allow") by SrcIP
| top 5 by Attempts
```

### 6.6 Scenario C · Failures and errors (DNS and NetScaler)  
*(slide 104)*

**DNS failures: which names and how many clients?**

```kusto
Infoblox_DNS_CL
| where EventType == "QueryFailure"
| summarize Failures=count(), Clients=dcount(ClientIP) by DnsQuery, FailureReason
| sort by Failures desc
```

**NetScaler: errors and policy messages by category**

```kusto
Netscaler_Logs_CL
| where Module == "APPFW" or Payload contains "errno"
| summarize Events=count() by Module, EventType
| sort by Events desc
```

### 6.7 Library: more firewall queries  
*(slide 105)*

**Allowed vs blocked**

```kusto
Palo_FW_CL
| summarize Connections=count() by Action
| sort by Connections desc
```

**Most active source IPs**

```kusto
Palo_FW_CL
| summarize Connections=count() by SrcIP
| top 10 by Connections
```

**Firewall events over time**

```kusto
Palo_FW_CL
| summarize Events=count() by bin(TimeGenerated, 10s)
| sort by TimeGenerated asc
```

### 6.8 Library: more DNS and DHCP queries  
*(slide 106)*

**DNS: what one client is asking**

```kusto
Infoblox_DNS_CL
| where ClientIP == "10.192.132.14"
| summarize Queries=count() by DnsQuery
| top 10 by Queries
```

**DNS: query failures with the reason**

```kusto
Infoblox_DNS_CL
| where EventType == "QueryFailure"
| project TimeGenerated, ClientIP, DnsQuery, FailureReason
```

**DHCP: recent lease-related activity**

```kusto
Infoblox_DHCP_CL
| where EventType in ("DHCPACK", "DHCPRELEASE", "AbandonedLease")
| top 20 by TimeGenerated
| project TimeGenerated, EventType, LeaseIP, ClientMAC, ClientHostname
```

### 6.9 Library: more NetScaler queries  
*(slide 107)*

**Recent events**

```kusto
Netscaler_Logs_CL
| top 20 by TimeGenerated
| project TimeGenerated, DeviceName, Module, EventType, ClientIP, Payload
```

**Search for a client IP**

```kusto
Netscaler_Logs_CL
| where ClientIP == "10.21.1.142" or SrcIP == "10.21.1.142"
| project TimeGenerated, DeviceName, Module, EventType, ClientIP, SrcIP
```

**Data received per client (connection statistics)**

```kusto
Netscaler_Logs_CL
| where EventType == "TCPCONNSTAT"
| summarize Connections=count(), BytesReceived=sum(BytesReceived) by ClientIP
| top 5 by BytesReceived
```


## Instructor appendix


---

*End of companion file. Generated together with the slide deck so queries and order stay in sync.*
