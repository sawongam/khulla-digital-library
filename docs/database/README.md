# Database

How Khulla stores its catalogue: SQLite on the device, accessed through drift. No backend, no server.

| File                       | What it is                                                                                      |
| -------------------------- | ----------------------------------------------------------------------------------------------- |
| [overview.md](overview.md) | What and why - every database file, the connection, the error boundary, the startup sequence    |
| [guide.md](guide.md)       | How-to - adding tables and columns, writing queries, running migrations, removing things safely |
| [schema.md](schema.md)     | The visual schema - generated Mermaid ER diagram, regenerated with `make db-diagram`            |

Start with the overview, keep the guide open while working, and never hand-edit the schema diagram.
