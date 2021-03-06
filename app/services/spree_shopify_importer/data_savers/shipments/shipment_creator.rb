module SpreeShopifyImporter
  module DataSavers
    module Shipments
      class ShipmentCreator < BaseDataSaver
        delegate :attributes, :number, :timestamps, to: :parser

        def initialize(shopify_data_feed, parent_feed, spree_order)
          super(shopify_data_feed)
          @parent_feed = parent_feed # shopify order data feed
          @spree_order = spree_order
        end

        def create!
          Spree::Shipment.transaction do
            find_or_initialize_shipment
            save_shipment_with_attributes
            create_shipping_rate
            create_inventory_units
            assign_spree_shipment_to_data_feed
          end
          @spree_shipment.update_columns(timestamps)
        end

        private

        def find_or_initialize_shipment
          @spree_shipment = @spree_order.shipments.find_or_initialize_by(number: number)
        end

        def save_shipment_with_attributes
          @spree_shipment.assign_attributes(attributes)
          @spree_shipment.save!(validate: false)
        end

        def assign_spree_shipment_to_data_feed
          @shopify_data_feed.update(spree_object: @spree_shipment)
        end

        def create_shipping_rate
          SpreeShopifyImporter::DataSavers::ShippingRates::ShippingRateCreator.new(
            shopify_shipping_line,
            shopify_order,
            @spree_shipment
          ).create!
        end

        def create_inventory_units
          shopify_fulfillment.line_items.each do |shopify_line_item|
            SpreeShopifyImporter::DataSavers::InventoryUnits::InventoryUnitsCreator.new(shopify_line_item,
                                                                                        @spree_shipment).create!
          end
        end

        def shopify_shipping_line
          shopify_order.shipping_lines.first
        end

        def shopify_order
          ShopifyAPI::Order.new(JSON.parse(@parent_feed.data_feed))
        end

        def parser
          @parser ||= SpreeShopifyImporter::DataParsers::Shipments::BaseData.new(shopify_fulfillment)
        end

        def shopify_fulfillment
          @shopify_fulfillment ||= ShopifyAPI::Fulfillment.new(data_feed)
        end
      end
    end
  end
end
