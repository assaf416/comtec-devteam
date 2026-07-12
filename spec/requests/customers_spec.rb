require 'rails_helper'

RSpec.describe "Customers", type: :request do
  let(:user)     { create(:user) }
  let!(:customer) { create(:customer) }

  before { sign_in user }

  # ── GET /customers ─────────────────────────────────────────────────────────
  describe "GET /customers" do
    it "returns http success" do
      get customers_path
      expect(response).to have_http_status(:success)
    end

    it "displays the customer name" do
      get customers_path
      expect(response.body).to include(customer.name)
    end

    it "filters by search query" do
      other = create(:customer, name: "Totally Unique XYZ Corp")
      get customers_path, params: { q: "Totally Unique XYZ" }
      expect(response.body).to include("Totally Unique XYZ Corp")
      expect(response.body).not_to include(customer.name)
    end

    it "filters to active only" do
      inactive = create(:inactive_customer)
      get customers_path, params: { active_only: "1" }
      expect(response.body).not_to include(inactive.name)
    end
  end

  # ── GET /customers/new ────────────────────────────────────────────────────
  describe "GET /customers/new" do
    it "returns http success" do
      get new_customer_path
      expect(response).to have_http_status(:success)
    end
  end

  # ── POST /customers ───────────────────────────────────────────────────────
  describe "POST /customers" do
    let(:valid_params) do
      { customer: { name: "Acme Corp", email: "acme@example.com",
                    company: "Acme", phone: "555-1234",
                    contact_person: "Jane Doe", active: true } }
    end

    context "with valid params" do
      it "creates a customer and redirects to show" do
        expect {
          post customers_path, params: valid_params
        }.to change(Customer, :count).by(1)
        expect(response).to redirect_to(customer_path(Customer.last))
      end

      it "sets flash notice" do
        post customers_path, params: valid_params
        follow_redirect!
        expect(response.body).to include("created")
      end
    end

    context "with invalid params" do
      it "re-renders new on blank name" do
        post customers_path, params: { customer: { name: "", email: "x@x.com" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "re-renders new on blank email" do
        post customers_path, params: { customer: { name: "Corp", email: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "re-renders new on duplicate email" do
        post customers_path, params: { customer: { name: "Dupe", email: customer.email } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # ── GET /customers/:id ────────────────────────────────────────────────────
  describe "GET /customers/:id" do
    it "returns http success" do
      get customer_path(customer)
      expect(response).to have_http_status(:success)
    end

    it "displays customer details" do
      get customer_path(customer)
      expect(response.body).to include(customer.name)
      expect(response.body).to include(customer.email)
    end

    it "shows the customer's support tickets" do
      ticket = create(:customer_ticket, customer: customer)
      get customer_path(customer)
      expect(response.body).to include(ticket.title)
    end
  end

  # ── GET /customers/:id/edit ───────────────────────────────────────────────
  describe "GET /customers/:id/edit" do
    it "returns http success" do
      get edit_customer_path(customer)
      expect(response).to have_http_status(:success)
    end

    it "pre-populates the customer name" do
      get edit_customer_path(customer)
      expect(response.body).to include(customer.name)
    end
  end

  # ── PATCH /customers/:id ──────────────────────────────────────────────────
  describe "PATCH /customers/:id" do
    context "with valid params" do
      it "updates the customer and redirects to show" do
        patch customer_path(customer), params: { customer: { name: "Updated Name" } }
        expect(response).to redirect_to(customer_path(customer))
        expect(customer.reload.name).to eq("Updated Name")
      end
    end

    context "with invalid params" do
      it "re-renders edit on blank name" do
        patch customer_path(customer), params: { customer: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "re-renders edit on invalid email" do
        patch customer_path(customer), params: { customer: { email: "not-an-email" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # ── DELETE /customers/:id ────────────────────────────────────────────────
  describe "DELETE /customers/:id" do
    it "destroys the customer and redirects to index" do
      expect {
        delete customer_path(customer)
      }.to change(Customer, :count).by(-1)
      expect(response).to redirect_to(customers_path)
    end
  end

  # ── Unauthenticated access ────────────────────────────────────────────────
  describe "when not signed in" do
    before { sign_out user }

    it "redirects index to sign-in" do
      get customers_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects show to sign-in" do
      get customer_path(customer)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
