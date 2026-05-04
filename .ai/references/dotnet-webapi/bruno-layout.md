# Bruno collections — directory layout for manual / exploratory testing

Collections live in `bruno/`, committed to Git. One folder per module, mirroring API routes.

```
bruno/
├── bruno.json
├── environments/
│   ├── local.bru
│   └── staging.bru
└── <module>/
    ├── create-<entity>.bru
    ├── get-<entity>-by-id.bru
    ├── update-<entity>.bru
    └── delete-<entity>.bru
```

- One folder per module
- Request files named for the action: `create-order.bru`, `get-order-by-id.bru`
- Base URLs and tokens via Bruno environments — never hardcoded in `.bru` files
- When an endpoint is added or changed, the corresponding Bruno request is added or updated in the same PR
- Include realistic example bodies and useful assertions (status code, response shape)
