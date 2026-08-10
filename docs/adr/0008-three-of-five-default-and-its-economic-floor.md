# 3-of-5 by default, and the economic floor it implies

The default federation is 3-of-5. 2-of-3 is offered for testing and for small values.
The operator is not asked to choose a threshold from first principles, and is not asked
what the vault holds.

We chose an opinionated default because 3-of-5 is established practice for serious
Bitcoin custody, and because asking someone who cannot use ssh to price a security
trade-off is asking them to guess. A named, defensible default is more honest than a
control they will accept unchanged anyway.

## Consequences

**Every member is a recurring bill, and the bill is the real constraint.** At the
`cx22` price used in the harness fixtures, €4.59/month:

| Configuration | Machines | Annual cost |
|---|---|---|
| 3-of-5 | 5 | €275 |
| 2-of-3 | 3 | €165 |

**This defines the audience more narrowly than the product thesis does.** At a
willingness to pay roughly 1% per year for custody, 3-of-5 implies holdings near
€27,500 and 2-of-3 implies near €16,500. There is no configuration that makes sense
for someone holding €1,000, because the floor is three machines and three machines cost
what they cost.

The target operator is therefore **a non-technical person with meaningful Bitcoin**,
not a non-technical person generally. That is a better target — they have real reason
to leave a custodian, and the fee for procured inference is negligible against the
amount at stake — but it should be stated rather than discovered by someone who
budgeted for a €5 hobby.

**Cheaper members are the lever, if the floor needs lowering.** Smaller ARM instances,
or renting through lnrent for sats, reduce the per-member cost without touching the
threshold. Reducing the member *count* is not available: it is the security parameter.

**The recurring nature must be visible before the first machine is created.** The
domain model already carries `Price { hourly, monthly }`, so the information exists;
the approval screen has to show the annual figure for the whole federation, not the
hourly figure for one machine.
