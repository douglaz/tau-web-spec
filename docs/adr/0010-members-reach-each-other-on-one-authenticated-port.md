# Members reach each other on one authenticated port, everything else denied

Federation members can open connections to each other only on the vault protocol port,
mutually authenticated. No SSH between members, no arbitrary traffic, everything else
denied at the vendor firewall — which makes the rule a cloud-plane action and therefore
part of what the operator approves.

## The problem this addresses

[ADR-0004](./0004-one-model-one-machine.md) restricts which machine a model may access.
It says nothing about network topology, and **network reachability is a foothold on the
same terms as a credential**. If the five machines can reach each other, a model that
controls machine 1 can attack machines 2 through 5 directly, and the invariant is
broken by the network rather than by any grant.

This matters more than it first appears because a k-of-n threshold assumes faults are
**independent**. One model able to attack four other machines produces *correlated*
faults, which is the one assumption a Byzantine threshold cannot survive losing. The
hole does not merely add risk; it undermines the reasoning that everything else rests
on.

## Considered options

**Full isolation, with the coordinator relaying every message between members.** This
closes the hole completely and was the preferred option. Rejected because the vault
protocol requires peer-to-peer contact at runtime, so routing everything through the
operator's device would mean the federation only functions while the app is open — an
unacceptable interaction with
[ADR-0003](./0003-the-ai-runs-only-in-the-browser.md), which already means nothing
*provisions* while the app is closed. A vault that also cannot *operate* while the app
is closed is not a vault.

**Mutual reachability, relying on the threshold to absorb it.** Rejected for the
correlated-faults reason above.

## Consequences

**The vault protocol must be safe against actively hostile peers**, not merely faulty
ones, because a compromised member can still send well-formed protocol messages to
every other member. **This is confirmed to be btc-policy's own premise**, not a new
requirement this decision imposes: a policy co-signer inspects exact PSBTs precisely
because it does not trust its peers. The reachability decision therefore rests on a
property the vault already guarantees, rather than on one it would have to acquire.

**A pentest cannot run from another member.** One member scanning another is the same
foothold wearing a helpful hat. Security checks run from the machine itself
(see [ADR-0011](./0011-the-ai-delivers-a-locked-down-machine.md)) or from the trusted
coordinator, never sideways.

**Firewall rules are cloud-plane and therefore approved.** The deny-by-default posture
is visible to the operator rather than being an implementation detail, and a recipe
cannot quietly widen it — widening requires a typed operation and an approval.
