# Hacking Nepenthes

# So you want to write a worker

Writing another worker is designed to be easy. (It may or may not fall short, but that's the goal.) If you want to write a new worker, you'll probably want to split it into two parts: the part that actually needs to reach a server, and a part for processing the data and storing results into the database. (This separation is good because occasionally scans need to be run on a client site across a VPN, or on several remote, partially-trusted machines without access to your database.)

## The setup

I recommend copying `ssl_worker.rb` and `ssl_results.rb` to files for your own worker. For simplicity, name one `[type]_worker.rb` and `[type]_results.rb`, so people know where to look. 

## foo_worker.rb

The worker you use shouldn't require any access to the database or any ActiveRecord models. Pass in any address you want to use as an actual parameter, rather than trying to synthesize it in the worker. Perform your work/scan/etc., and then pass the results back to your results worker. Be sure to send any relevant ID to your results worker, so it can update the database.

## foo_results.rb

Your results worker should be run on the results queue, and can interact with the database. It should process the data from the worker (if necessary), update the database, and quit. Results workers tend to be fairly quick to execute, compared to the normal worker. (Keep in mind that large netpens may have dozens or hundreds of normal worker threads running, but only one or two result worker threads running.)

# Extending models

Feel free to extend models as necessary, but note that both IpAddress and Port have JSON-serialized `.settings` properties, where you can stash results if necessary. This may be appropriate for extra data that will not need to be queried directly, rather than adding another column to the database. On the other hand, never underestimate the usefulness of being able to query based on the results of your worker.

Most workers will likely not need their own model for results, but some may. Anything that can be assumed to always be the same for a given object (such as the SSL details on a given port, or the reverse DNS for an IP address) should be set on that object. Anything that may have multiple results for its parent should consider adding a model. For example, scans have their own model, as it is reasonable to run multiple scans on a given IP address, and screenshots have their own model, as it's possible that screenshotting subdirectories would be desirable.

# Displaying results

You should expose the results of your worker to the user in the user interface. For scans that operate on ports, this should be relatively straightforward: modify the `/app/views/ports/_port.html.erb` template to display your worker's results if they exist and are relevant.

If your result display is likely to be large and/or not frequently accessed, you may consider hiding it in some fashion (for example, under a toggle display). You may also consider making a new page in the interface (either under an existing controller if it fits, or as a new controller), particularly if your results are likely to be large or otherwise unwieldy, or if you want to browse them in a different fashion.
