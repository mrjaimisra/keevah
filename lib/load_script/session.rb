require "logger"
require "pry"
require "capybara"
require 'capybara/poltergeist'
require "faker"
require "active_support"
require "active_support/core_ext"

module LoadScript
  class Session
    include Capybara::DSL
    attr_reader :host

    def initialize(host = nil)
      options = { js_errors: false }
      Capybara.default_driver = :poltergeist
      Capybara.register_driver :poltergeist do |app|
        Capybara::Poltergeist::Driver.new(app, options)
      end
      @host = host || "http://localhost:3000"
    end

    def logger
      @logger ||= Logger.new("./log/requests.log")
    end

    def session
      @session ||= Capybara::Session.new(:poltergeist)
    end

    def run
      while true
        run_action(actions.sample)
      end
    end

    def run_action(name)
      benchmarked(name) do
        send(name)
      end
    rescue Capybara::Poltergeist::TimeoutError
      logger.error("Timed out executing Action: #{name}. Will continue.")
    end

    def benchmarked(name)
      logger.info "Running action #{name}"
      start = Time.now
      val = yield
      logger.info "Completed #{name} in #{Time.now - start} seconds"
      val
    end

    def actions
      [:browse_loan_requests,
       :sign_up_as_lender,
       :sign_up_as_borrower,
       :browse_categories,
       :browse_category_pages,
       :borrower_creates_loan_request,
       :lender_makes_loan]
    end

    def log_in(email="demo+horace@jumpstartlab.com", pw="password")
      log_out
      session.visit host
      session.click_link("Log In")
      session.fill_in("email_address", with: email)
      session.fill_in("password", with: pw)
      session.click_link_or_button("Login")
      "logged in"
    end

    def browse_loan_requests
      session.visit "#{host}/browse"
      session.all(".lr-about").sample.click
      puts "browsed new loan request"
    end

    def log_out
      session.visit host
      if session.has_content?("Log out")
        session.find("#logout").click
      end
      puts "logged out"
    end

    def new_user_name
      "#{Faker::Name.name} #{Time.now.to_i}"
    end

    def new_user_email(name)
      "TuringPivotBots+#{name.split.join}@gmail.com"
    end

    def sign_up_as_lender(name = new_user_name)
      log_out
      session.find("#sign-up-dropdown").click
      session.find("#sign-up-as-lender").click
      session.within("#lenderSignUpModal") do
        session.fill_in("user_name", with: name)
        session.fill_in("user_email", with: new_user_email(name))
        session.fill_in("user_password", with: "password")
        session.fill_in("user_password_confirmation", with: "password")
        session.click_link_or_button "Create Account"
      end
      puts "signed up new lender"
    end

    def sign_up_as_borrower(name = new_user_name)
      log_out
      session.find("#sign-up-dropdown").click
      session.find("#sign-up-as-borrower").click
      session.within("#borrowerSignUpModal") do
        session.fill_in("user_name", with: name)
        session.fill_in("user_email", with: new_user_email(name))
        session.fill_in("user_password", with: "password")
        session.fill_in("user_password_confirmation", with: "password")
        session.click_link_or_button "Create Account"
      end
      puts "signed up new borrower"
    end

    def categories
      ["Agriculture", "Education", "Youth"]
    end

    def random_category
      categories.sample
    end

    def browse_categories
      session.visit "#{host}/categories"
      puts "browsing categories"
    end

    def browse_category_pages
      session.visit "#{host}/browse"
      session.click_on "Categories"
      session.click_on random_category
      puts "browsing category page"
    end

    def borrower_creates_loan_request
      sign_up_as_borrower(name = new_user_name)
      session.click_on("Create Loan Request")
      session.fill_in("Title", with: "title")
      session.fill_in("Description", with: "description")
      session.fill_in("Image url", with: "image_url")
      session.fill_in("Requested by date", with: "11/11/2015")
      session.fill_in("Repayment begin date", with: "11/11/2015")
      session.select("Monthly", from: "loan_request[repayment_rate]")
      session.select("Agriculture", from: "Category")
      session.fill_in("Amount", with: "100")
      session.click_on("Submit")
      log_out
      puts "loan request created"
    end

    def lender_makes_loan
      sign_up_as_lender(name = new_user_name)
      session.click_link("Lend")
      session.visit "#{host}/browse"
      session.all(".contribute").sample.click
      session.click_on("Basket")
      session.click_on("Transfer Funds")
      log_out
      puts "lender made loan"
    end
  end
end
