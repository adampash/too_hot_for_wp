## Too Hot for WP

This dumb and also excellent thing tracks, archives, and notifies you (well, not you, because right now the recipients are hard-coded) of articles deleted from Wikipedia.

## Development

```bash
foreman start
```

## Set up in Heroku

Most deployment bits are fairly standard, in terms of configuring your database and email. The main thing is the Heroku Scheduler, in which I've set up an hourly run of `rake task` and a daily run of `rake digest`.

## ??

This is mostly documentation for me. If you'd like to use this in any capacity and would like more info, just reach out and I'll be happy to explain in more detail.
