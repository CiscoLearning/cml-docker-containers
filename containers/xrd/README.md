# README

The binary XRd image must be downloaded from CCO and provided in this
directory. In addition, the `.disabled` file/flag must be deleted.

Make sure that the version in `vars.mk` matches the version in the file name.

Example: `xrd-control-plane-container-x86.25.2.2.tgz`, version is `var.mk` is
then `25.2.2`.

<https://www.cisco.com/c/en/us/support/routers/ios-xrd/series.html>

In case there's older XRd instances in CML which have the wrong node type, then
the below SQL can be used to update them to what's currently used in the node
definition:

```sql
UPDATE node SET node_definition="ios-xrd-control-plane" WHERE node_definition="xrd";
```
