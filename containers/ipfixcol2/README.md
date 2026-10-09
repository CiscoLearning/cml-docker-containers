# IPFIXcol2 Container Investigation

This directory is intentionally documentation-only for now. There is no
`Dockerfile`, so the top-level build system will not discover or build this as a
container yet.

## Upstream

- Repository: <https://github.com/CESNET/ipfixcol2>
- Purpose: high-performance NetFlow v5/v9 and IPFIX collector.
- Current investigated release: `v2.8.0`.
- Required library: `libfds` from <https://github.com/CESNET/libfds>.
- License metadata on GitHub is `NOASSERTION`; check upstream license before
  redistribution.

IPFIXcol2 is plugin based:

- Input plugins receive NetFlow/IPFIX, commonly UDP or TCP on port `4739`.
- Intermediate plugins can modify/enrich records.
- Output plugins store, print, forward, or stream converted records.

## Container Build Direction

The simplest CML-friendly image would be a Debian-based collector container with
an editable Day-0 XML config mounted from the node definition.

Recommended first build path:

1. Base image: `debian:bookworm-slim`.
2. Install upstream release `.deb` packages for `libfds` and `ipfixcol2`.
3. Copy or mount a default `/etc/ipfixcol2/ipfixcol2.xml`.
4. Run `ipfixcol2 -v -c /etc/ipfixcol2/ipfixcol2.xml`.

Upstream release assets include Debian packages such as:

- `debian.bookworm-libfds_0.6.0-1_amd64.deb`
- `debian.bookworm-ipfixcol2_2.8.0-1_amd64.deb`

Building from source is possible but heavier:

1. Build and install `libfds`.
2. Build and install `ipfixcol2`.
3. Install build dependencies such as `gcc`, `g++`, `cmake`, `make`,
   `python3-docutils`, `zlib1g-dev`, and `librdkafka-dev`.
4. Use a multi-stage Dockerfile to keep the runtime image small.

## CML Node Shape

A future implementation should follow the existing container pattern in this
repository:

- `Dockerfile`
- `vars.mk`
- `node-definition`
- optional `Makefile` using `../../templates/build.mk`

Useful node defaults:

- `eth0` as management.
- optional `eth1+` as data-plane interfaces for exporters.
- one CPU and `512M` to `1G` RAM for basic collection.
- more CPU/RAM when using high-rate ingestion or ClickHouse output.
- Day-0 editable `ipfixcol2.xml` and `boot.sh`.

Suggested default collector behavior:

- listen for IPFIX/NetFlow on UDP `4739`.
- optionally also listen on TCP `4739`.
- emit JSON to stdout and/or a TCP JSON server on port `8000`.

## Useful Output Options

### JSON

Best general-purpose output.

The JSON output plugin can:

- print records to stdout.
- write rotating JSON files.
- send records to a remote TCP or UDP endpoint.
- expose a local TCP server, commonly port `8000`.
- send records to Kafka.

The TCP server is not a web UI. It is a stream of converted JSON records to all
connected TCP clients. It is a good integration point for Splunk, custom web
viewers, log collectors, or bridges.

### Viewer

Human-readable stdout output. Useful for demos, troubleshooting, and seeing
record structure. Not intended for stable machine parsing.

### Overview

Prints a JSON summary on exit showing which IPFIX fields were observed. Useful
for validating exporters and identifying missing enterprise field definitions.

### FDS

Stores records in Flow Data Storage format for efficient retention. Useful for
preservation/replay workflows, less useful for immediate dashboarding. Upstream
marks this plugin as beta.

### Forwarder

Forwards flows as IPFIX to another collector. Useful when the CML node should act
as a relay.

### Kafka

Good for external pipelines, but heavy for a standalone CML demo unless Kafka is
provided separately.

### Extra Plugins

Upstream extra output plugins include:

- `lnfstore`: nfdump-compatible storage, with extra dependencies.
- `unirec`: NEMEA/UniRec integration.
- `clickhouse`: direct high-performance inserts into ClickHouse.

Extra plugins are not installed by default and must be built/installed
separately.

## Splunk Integration

Splunk can ingest IPFIXcol2 JSON cleanly.

Preferred flow:

```text
exporter -> IPFIXcol2 -> JSON output -> HEC bridge -> Splunk HTTP Event Collector
```

IPFIXcol2 does not appear to speak Splunk HEC directly. The cleanest Splunk path
is therefore a small bridge that reads newline-delimited JSON from the IPFIXcol2
JSON TCP server or file output and posts to Splunk HEC.

Other viable Splunk paths:

- JSON file output plus Splunk file monitoring.
- JSON TCP send output into a Splunk TCP input configured for JSON events.

The existing Splunk container in this repository could be paired with a future
IPFIXcol2 node for demos.

## Grafana And ClickHouse Integration

Grafana needs a queryable datastore. ClickHouse is the best fit found for flow
analytics.

Recommended topology:

```text
exporter -> IPFIXcol2 collector -> ClickHouse output plugin -> ClickHouse -> Grafana
```

This should normally use separate CML container nodes:

- IPFIXcol2 collector node.
- ClickHouse database node.
- Grafana dashboard node.

Combining all three into one container is possible but not recommended. It would
increase image size, mix multiple daemons, complicate startup ordering, and make
persistence harder.

### ClickHouse Plugin Notes

The ClickHouse output plugin writes via the native ClickHouse protocol, typically
TCP port `9000`. It maps selected IPFIX fields to ClickHouse table columns.

Important constraints:

- The plugin is an extra plugin and is not distributed with the default
  IPFIXcol2 package.
- IPFIXcol2 and its header files must be installed before building the plugin.
- The ClickHouse database and table must already exist.
- The plugin checks the table schema at startup and fails on mismatch.

Example ClickHouse schema from upstream:

```sql
CREATE DATABASE IF NOT EXISTS ipfixcol2;

CREATE TABLE ipfixcol2.flows (
    odid UInt32,
    srcip IPv6,
    dstip IPv6,
    flowstart DateTime64(9),
    flowend DateTime64(9),
    sourceTransportPort UInt16,
    destinationTransportPort UInt16,
    protocolIdentifier UInt8,
    octetDeltaCount UInt64,
    packetDeltaCount UInt64,
    INDEX srcipindex srcip TYPE bloom_filter GRANULARITY 16,
    INDEX dstipindex dstip TYPE bloom_filter GRANULARITY 16
)
ENGINE = MergeTree
PARTITION BY toStartOfInterval(flowstart, INTERVAL 1 HOUR)
ORDER BY flowstart;
```

Useful helper function for dashboards:

```sql
CREATE FUNCTION ipToString AS (ip) ->
    if(isIPAddressInRange(toString(ip), '::ffff:0.0.0.0/96'), toString(toIPv4(ip)), toString(ip));
```

Example IPFIXcol2 ClickHouse output shape:

```xml
<output>
  <name>ClickHouse output</name>
  <plugin>clickhouse</plugin>
  <params>
    <connection>
      <endpoints>
        <endpoint>
          <host>clickhouse</host>
          <port>9000</port>
        </endpoint>
      </endpoints>
      <user>ipfixcol2</user>
      <password>ipfixcol2</password>
      <database>ipfixcol2</database>
      <table>flows</table>
    </connection>
    <splitBiflow>true</splitBiflow>
    <nonblocking>true</nonblocking>
    <columns>
      <column><name>odid</name></column>
      <column><name>srcip</name></column>
      <column><name>dstip</name></column>
      <column><name>flowstart</name></column>
      <column><name>flowend</name></column>
      <column><name>sourceTransportPort</name></column>
      <column><name>destinationTransportPort</name></column>
      <column><name>protocolIdentifier</name></column>
      <column><name>octetDeltaCount</name></column>
      <column><name>packetDeltaCount</name></column>
    </columns>
  </params>
</output>
```

Example Grafana/ClickHouse queries:

```sql
SELECT
  toStartOfMinute(flowstart) AS t,
  sum(octetDeltaCount) AS bytes
FROM ipfixcol2.flows
WHERE $__timeFilter(flowstart)
GROUP BY t
ORDER BY t;
```

```sql
SELECT
  ipToString(srcip) AS src,
  sum(octetDeltaCount) AS bytes
FROM ipfixcol2.flows
WHERE $__timeFilter(flowstart)
GROUP BY src
ORDER BY bytes DESC
LIMIT 20;
```

## Open Questions

- Should the first implementation be a minimal JSON-output collector, or should
  it include the ClickHouse extra plugin from the start?
- Should ClickHouse and Grafana be added as separate first-class container
  modules in this repository?
- What is the expected CML scale: low-rate demos, or sustained high-rate flow
  ingestion?
- Is the intended collector input UDP only, TCP only, or both?
- Are persistent volumes required for stored flow data?
