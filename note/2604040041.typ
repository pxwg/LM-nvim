#import "../include.typ": *
#let zk-metadata = toml(bytes(
  ```toml
  schema-version = 1
  aliases = []
  abstract = ""
  keywords = []
  generated = true
  checklist-status = "none"
  relation = "active"
  relation-target = []
  ```.text,
))
#show: zettel.with(metadata: zk-metadata)

=  <2604040041>
