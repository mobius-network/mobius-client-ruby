# rubocop:disable Metrics/AbcSize
def check_deltas(app_delta:, user_delta:, target_delta: nil)
  start_app_balance = app.app_balance
  start_user_balance = app.user_balance
  start_target_balance = target_account.balance if target_delta

  yield

  if target_delta
    target_account.reload!
    expect(target_account.balance - start_target_balance).to eq(target_delta)
  end

  expect(app.app_balance - start_app_balance).to eq(app_delta)
  expect(app.user_balance - start_user_balance).to eq(user_delta)
end
# rubocop:enable Metrics/AbcSize
