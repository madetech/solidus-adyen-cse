def fill_in_login(email = 'user@example.com', password = 'password')
  within '#existing-customer' do
    fill_in 'spree_user[email]', with: email
    fill_in 'spree_user[password]', with: password
    find('input[type="submit"]').click
  end
end

def login(email = 'admin@example.com', password = 'password')
  visit spree.login_path
  fill_in_login(email, password)
end
