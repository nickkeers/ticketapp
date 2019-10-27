# DICE tech test - Nick Keers

## Technology used

* [Phoenix Framework](https://phoenixframework.org/) - I've standardised on the Phoenix Framework at my current workplace as it makes building
web API's extremely easy. The structure that Phoenix enforces means that your code is easy to read and navigate, in a standard directory layout which is shared across projects -  and by default is easily testable (as long as you use Context modules as is suggested).
* [Postgres](https://www.postgresql.org/) - I'm a huge fan of Postgres, its a very mature Open-Source project which implements the current SQL standard as well a few extra goodies on top. Postgres is by far the least-surprising database I've used - compared to MySQL it's a breath of fresh air, and I wouldn't consider using any another relational database right now.
* [TailwindCSS](https://tailwindcss.com/) - Tailwind is an atomic CSS framework, I personally find it makes building UI's a lot easier as a developer as it gives you a lot of "building blocks" to combine into your finished product.

I've setup the webpack config with PostCSS so that I could use Tailwind (check out the imports in assets/css/app.css) and also PurgeCSS which will remove any unused CSS classes - making the bundle size drastically smaller - for production.

## Libraries

* [stripity_stripe](https://hex.pm/packages/stripity_stripe) - Seemed to be the easiest way to get going with the new Stripe API.
* [ex_doc](https://hex.pm/packages/ex_doc) - ExDoc is a no-brainer, every project should use it to generate beautiful code documentation.

## First time setup

Check database config in `config/dev.exs` first.

```
mix ecto.create
mix ecto.migrate
```

Run with:

```
mix phx.server
```

Navigate to: http://localhost:4000. You will be redirected to the payment form.

## Initial thoughts

I'm putting this section here so that I can refer back to it later, here are some problems I can forsee having before writing any code:

## Checking the number of tickets available whilst accounting for concurrent requests.

There are a few approaches that could work here:

1. Check purely in the database - create a trigger that only allows 5 rows to be inserted into the table. Whilst writing this I've just added a "confirmed" field to the tickets table, so when the payment intent is first made I could create a row with the confirmed status as false, when the payment is accepted I can change the confirmed field to true. The trigger could run ON UPDATE and only allow 5 rows with confirmed == TRUE.
    * Pros: Guaranteed to work with multiple updates etc happening, as the row / table can be locked as needed.
    * Cons: Opaque - logic lives in the database, i've seen this problem at my past employer and at my current employer, it quickly becomes a nightmare to deal with.
2. Check the row count when inserting / updating from the application. With the approach described above when editing the confirmed field this won't work anymore. If i was just limiting the number of rows then it would have been easier, off the top of my head I can't think of an easy way to only update a field if there are < 5 other records.
3. Keep state in the application, since this is a small problem then I could just create a GenServer or similar that holds the available number of tickets and when a new purchase comes through reserve one. The ticket would have to be held for a fixed amount of time as a user could put a request in for a ticket and then close their browser - the request could still come through to the GenServer to reserve the ticket, and then it'd be stuck. It'd be trivial just to set a time period to hold the ticket for e.g 10s and have a timer repeatedly run and reset the state of tickets back if the purchase hasn't completed yet. For this task, this approach might be the easiest, the biggest pro here is that it reduces load on the database by a large margin, and keeps business logic in the application. For this task, one GenServer would be enough to hold tickets, but in a production application where you need to be able to handle more traffic a different approach would be needed to avoid the single-process bottleneck; you would need to hold state across a cluster e.g by using something like Swarm + LibCluster to spawn "ticket servers" - you could start 5 workers and they could be spread throughout your cluster. Or you could use something like Raft and distribute process using a master node.

