# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Management
      class Accounts < Grape::API
        desc 'Queries the account balance for the given UID and currency.' do
          @settings[:scope] = :read_accounts
          success API::V2::Management::Entities::Balance
        end

        params do
          requires :uid, type: String, desc: 'The shared user ID.'
          requires :currency, type: String, values: -> { Currency.codes(bothcase: true) }, desc: 'The currency code.'
        end

        post '/accounts/balance' do
          member = Member.find_by!(uid: params[:uid])
          account = member.get_account(params[:currency])
          present account, with: API::V2::Management::Entities::Balance
          status 200
        end

        desc 'Queries the accounts where balance is not nil for the given currency.' do
          @settings[:scope] = :read_accounts
          success API::V2::Management::Entities::Balance
        end

        params do
          requires :currency, type: String, values: -> { Currency.codes(bothcase: true) }, desc: 'The currency code.'
          optional :page,     type: Integer, default: 1,   integer_gt_zero: true, desc: 'The page number (defaults to 1).'
          optional :limit,    type: Integer, default: 100, range: 1..1000, desc: 'The number of deposits per page (defaults to 100, maximum is 1000).'
        end

        post '/accounts/balances' do
          currency = Currency.find(params[:currency])

          Account
            .tap { |q| q.where!(currency: currency) if currency }
            .tap { |q| q.where!('balance > ? OR locked > ?', 0, 0) }
            .page(params[:page])
            .per(params[:limit])
            .tap { |q| present q, with: API::V2::Management::Entities::Balance }
          status 200
        end
      end
    end
  end
end
