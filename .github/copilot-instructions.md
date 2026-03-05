When reviewing code, focus on:

## Security Critical Issues
- Check for hardcoded secrets, API keys, or credentials
- Check for instances of potential method call injection, dynamic code execution, symbol injection or other code injection vulnerabilities.

## Performance Red Flags
- Spot inefficient loops and algorithmic issues.
- Check for memory leaks and resource cleanup.

## Code Quality Essentials
- Methods should be focused and appropriately sized. If a method is doing too much, suggest refactorings to split it up.
- Use clear, descriptive naming conventions.
- Avoid encapsulation violations and ensure proper separation of concerns.
- All public classes, modules, and methods should have clear documentation in YARD format.
- If `method_missing` is implemented, ensure that `respond_to_missing?` is also implemented.
- Rubocop is used by this project to enforce code style. Always refer to the project's .rubocop.yml file for guidance on the project's style preferences.

## Mongoid-specific Concerns
- Mongoid::Document classes may be declared to exist in different database clusters. Look for code that should be multi-cluster-aware.
- Query state is stored on the current thread or fiber (depending on the current value of Mongoid::Config.isolation_level). Look for code that might fail in a multi-threaded or multi-fiber setup, including resources that ought to be protected by a synchronization mechanism.

## Review Style
- Be specific and actionable in feedback
- Explain the "why" behind recommendations
- Acknowledge good patterns when you see them
- Ask clarifying questions when code intent is unclear
- When possible, suggest that the pull request be labelled as a `bug`, a `feature`, or a `bcbreak` (a "backwards-compatibility break").
- PRs that change only tests or infrastructure configuration do not need to be labelled.

Always prioritize security vulnerabilities and performance issues that could impact users.

Always suggest changes to improve readability and testability. For example, this suggestion seeks to make the code more readable, reusable, and testable:

```ruby
  # Instead of:
  if (user.email && user.email.include?('@') && user.email.length > 5)
    submitButton.enabled = true
  else
    submitButton.enabled = false
  end
  
  # Consider:
  def valid_email?(email)
    email && email.include?('@') && email.length > 5
  end
  
  submitButton.enabled = valid_email?(user.email);
```

