# Goals

## Tell don’t ask

## General
- Prefer commit messages over comments
- Avoid local state
- Avoid comments

## Code AND Product Simplicity
- Slight preference to code simplicity over product edge cases
- Copy paste is a smell
- Limit branching
- Prefer fewer if/case statements

## Do one thing really well
- Prefer more API calls over complicating code
- Single use classes
- Consider “and” a smell
- Consider globals bad

## Easily testable
- Single unit of test
- Consider two levels of stubbing bad
- Conjoined triangles of success: unit tests over ui integration tests
- Prefer stubbing external resources but not things we control
- Fixtures over factories
- Accurate description of tests

## Should be able to know the state of the system
- Developers should be told of warnings or poor system performance, should not
  have to check

## Should be able to fail gracefully
- Prefer absolute values over computed
- Strongly prefer idempotent actions
- Developers should get notification when things break
- Should be able to prioritize tasks

