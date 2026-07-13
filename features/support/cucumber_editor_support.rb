# Reset the CucumberTestDeployer test seam between scenarios so a stubbed deploy
# result never leaks into another scenario.
After do
  CucumberTestDeployer.test_result = nil
end
