class AddSkuToOptionValues < ActiveRecord::Migration
  def self.up
    add_column :option_values, :sku, :string
  end

  def self.down
    remove_column :option_values, :sku
  end
end
