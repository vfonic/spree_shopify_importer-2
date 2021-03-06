module SpreeShopifyImporter
  module DataSavers
    module InventoryUnits
      class InventoryUnitsCreator
        delegate :attributes, :line_item, to: :parser

        def initialize(shopify_line_item, spree_shipment)
          @shopify_line_item = shopify_line_item
          @spree_shipment = spree_shipment
        end

        def create!
          Spree::InventoryUnit.transaction do
            @shopify_line_item.quantity.times do
              create_inventory_unit
            end
          end
        end

        private

        def create_inventory_unit
          @spree_shipment.inventory_units.create!(attributes)
        end

        def parser
          @parser ||=
            SpreeShopifyImporter::DataParsers::InventoryUnits::BaseData.new(@shopify_line_item, @spree_shipment)
        end
      end
    end
  end
end
