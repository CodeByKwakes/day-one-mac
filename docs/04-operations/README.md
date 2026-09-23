[← Day One Mac home](../README.md) · **Lifecycle operations** · [Command reference](../20-reference/COMMAND-REFERENCE.md)

# Finalise, roll back, remove, or clean Day One Mac

These operations have different scopes. Read the matching guide and preview the
result before executing it.

| Desired result | Guide | Preview command |
|---|---|---|
| Keep the environment but compact retained setup evidence | [Finalise](FINALIZE.md) | `day-one-mac finalize` |
| Reverse only files and packages recorded as Day One Mac changes | [Recorded rollback](ROLLBACK.md) | `day-one-mac rollback` |
| Choose recorded changes or individual sections to remove | [Guided removal](REMOVE-DAY-ONE-MAC.md) | `day-one-mac remove --guided` |
| Remove the broad Homebrew development environment | [Choose the correct removal meaning](REMOVE-DAY-ONE-MAC.md#choose-the-correct-removal-meaning) | `day-one-mac clean` |

None of these tools formats or erases the startup disk. Broad cleanup is still
destructive to Homebrew-managed software and development configuration, so its
recovery location and archive scope must be reviewed first.

---

[← Day One Mac home](../README.md) · [Complete command reference](../20-reference/COMMAND-REFERENCE.md)
