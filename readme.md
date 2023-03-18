## Test code to see the difference between aws_auth and aws_cognito_user_pools directives

### Deploy

* ```terraform init```
* ```terraform apply```

### Log in

```user // Password.1```

### Send requests to the two apis and see the difference

```graphql
query MyQuery {
  query_scalar
  outer {
    scalar
    inner {
      inner_scalar
    }
  }
}
```

### Cleanup

```terraform destroy```
