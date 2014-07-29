class Spree::Gateway::KlarnaInvoice < Spree::Gateway
  preference :id, :string
  preference :shared_secret, :string

  def provider_class
    # ActiveMerchant::Billing::KlarnaInvoice
    Spree::Gateway::KlarnaInvoice
  end

  def method_type
    'klarna_invoice'
  end

  def locale(order)
    "#{order.billing_address.country.iso.downcase}_#{order.billing_address.country.iso.upcase}"
  end

  def source_required?
    false
  end

  def birthday_required?(country)
    %w(DE AT NL).include? country.upcase
  end

  def sn_required?(country)
    %w(SE NO FI DK).include? country.upcase
  end

  def gender_required?(country)
      %w(DE).include? country.upcase
    end

  def process!(order,payment)
    p_no = order.billing_address.p_no
    gender = order.billing_address.gender
    client_ip = order.last_ip_address

    p "processing"
    Klarna.configure do |c|
        c.store_id = preferred_id
        c.store_secret = preferred_shared_secret
        c.mode = preferred_test_mode ?  :test : :production
        c.http_logging = true
        c.logging = true
      end

    klarna = ::Klarna::API::Client.new

    items = order.line_items.map do |prod|
        klarna.make_goods(prod.quantity.to_i, prod.variant.sku, prod.variant.name, to_klarna_i(prod.price + prod.additional_tax_total), to_klarna_i(prod.additional_tax_total))
    end
    if order.shipment_total > 0
      items << klarna.make_goods(1, "SHIPPING", "Shipping Fee", to_klarna_i(order.shipment_total), Klarna::API.id_for(:goods, :is_shipment))
    end
      # country = ::Klarna::API.id_for(:country, order.billing_address.country.iso)
      # language = ::Klarna::API.id_for(:language, order.billing_address.country.iso)
      # currency = ::Klarna::API.id_for(:currency, order.currency.to_s)
      # pno_format = ::Klarna::API.id_for(:pno_format, order.billing_address.country.iso)

      req ={
                                         :pno => p_no,
                                         # :gender => 1,
                                         :amount => to_klarna_i(order.total),
                                         :order_id => order.number,
                                         :delivery_address => {
                                             :email            => order.user.email,
                                             :telno            => order.shipping_address.phone,
                                             :cellno           => order.shipping_address.phone,
                                             :fname            => order.shipping_address.firstname,
                                             :lname            => order.shipping_address.lastname,
                                             :company          => '',
                                             :careof           => '',
                                             :street           => order.shipping_address.address1,
                                             :zip              => order.shipping_address.zipcode,
                                             :city             => order.shipping_address.city,
                                             :country          => ::Klarna::API.id_for(:country, order.shipping_address.country.iso ),
                                             :house_number     => order.shipping_address.address2,
                                             :house_extension  => ''
                                         },
                                         :billing_address => {
                                              :email            => order.user.email,
                                              :telno            => order.billing_address.phone,
                                              :cellno           => order.billing_address.phone,
                                              :fname            => order.billing_address.firstname,
                                              :lname            => order.billing_address.lastname,
                                              :company          => '',
                                              :careof           => '',
                                              :street           => order.billing_address.address1,
                                              :zip              => order.billing_address.zipcode,
                                              :city             => order.billing_address.city,
                                              :country          => ::Klarna::API.id_for(:country, order.billing_address.country.iso ),
                                              :house_number     => order.billing_address.address2,
                                              :house_extension  => ''
                                         },
                                         :client_ip => client_ip,
                                         :currency => ::Klarna::API.id_for(:currency, order.currency),
                                         :country => ::Klarna::API.id_for(:country, order.billing_address.country.iso),
                                         :language => ::Klarna::API.id_for(:language, order.billing_address.country.iso),
                                         :pno_encoding => ::Klarna::API.id_for(:pno_format, order.billing_address.country.iso),
                                         :pclass => -1,
                                         :goods_list => items,
                                     }
    req[:gender]=gender if gender
    ActiveRecord::Base.transaction do
      result = klarna.reserve_amount(req)
      if (result.is_a?(Array) && result.count == 2)
        payment.response_code=result[0]
        payment.state = result[1] == 1 ? :completed : :pending
        payment.save!
      end

    end
    # raise StandardError.new "stop"
  end

  private
  def to_klarna_i(number)
    (number*100).round
  end

end
