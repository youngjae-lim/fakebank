# How to register a domain and set up A-record using AWS Route53

- Buy a domain.
- Open up `Hosted zones` to connect our service to the domain.
  - Click `Create record`.
  - Fill out:
    - Record name: api
    - Record type: A - Routes traffic to an IPv4 address and some AWS resources
    - Value:
      - Switch on `Alias`
      - Select `Alias to Network Load Balancer`
      - Choose Region: `us-east-2` (whatever region you selected for your EKS cluster)
      - Copy and paste the url of load balancer: ac83f816e1ebe4b76a3fa2c18ae10b9f-1114365193.us-east-2.elb.amazonaws.com (note that you can find the url of load balancer from `k9s` console by typing `:services` and select the fakebank-api-service and hit 'd' to describe)

Once the A-record is successfully created, then test it out:

```shell
$ nslookup api.fake-bank.org
```

Now you can use Postman to try to login with the same user info we previously used:

- Make POST request with `http://api.fake-bank.org/users/login`

You should be able to log in without any issues.
