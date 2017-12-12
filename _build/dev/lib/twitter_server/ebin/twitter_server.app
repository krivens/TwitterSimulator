{application,twitter_server,
             [{applications,[kernel,stdlib,elixir,logger]},
              {description,"twitter_server"},
              {modules,['Elixir.TweetStore','Elixir.TwitterServer',
                        'Elixir.UserActor','Elixir.UserRegistry']},
              {registered,[]},
              {vsn,"0.1.0"},
              {extra_applications,[logger]}]}.
