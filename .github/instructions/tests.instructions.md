---
applyTo: "**/*Tests*/**"
---

# Test Instructions

Follow `.github/CONTRIBUTING.md` (Testing section).

Key requirements:
- **MSTest only** - no xUnit, no NUnit
- **Testcontainers** for external dependencies
- **In-memory database** for EF Core tests
- Test method naming: `{Method}_{Scenario}_{Expected}`
- Project naming: `{Organization}.{Product}.{Area}.{TestType}.Tests`
  - Unit: `MyOrganization.MyProduct.MyArea.Unit.Tests`
  - Integration: `MyOrganization.MyProduct.MyArea.Integration.Tests`
  - End-to-end: `MyOrganization.MyProduct.MyArea.E2E.Tests`
