# frozen_string_literal: true

# name: discourse-extended-product-fields
# about: Add custom product fields (category, name, price, image URL) to Discourse posts
# version: 0.1
# authors: zane
# url: https://azyex.com
# required_version: 2.7.0

module ::MyPluginModule
  PLUGIN_NAME = "discourse-extended-product-fields"
end

require_relative "lib/my_plugin_module/engine"

after_initialize do
  Rails.logger.info("✅ [PLUGIN DEBUG] discourse-extended-product-fields plugin loaded")

  require_dependency 'post_creator'

  # -----------------------------
  # 1️⃣ 重写 PostCreator#create 保存自定义字段
  # -----------------------------
  class ::PostCreator
    alias_method :original_create, :create

    def create
      Rails.logger.info("🔥 [PLUGIN DEBUG] PostCreator received opts: #{@opts.inspect}")

      post = original_create

      if post && @opts
        %i[product_category product_name product_price product_img_url].each do |field|
          value = @opts[field]
          if value.present?
            Rails.logger.info("✅ [PLUGIN DEBUG] Saving custom field #{field}: #{value}")
            post.custom_fields[field.to_s] = value
          end
        end

        post.save_custom_fields
      end

      post
    end
  end

  # -----------------------------
  # 2️⃣ 允许 POST 接口接收自定义字段参数
  # -----------------------------
  add_permitted_post_create_param(:product_category)
  add_permitted_post_create_param(:product_name)
  add_permitted_post_create_param(:product_price)
  add_permitted_post_create_param(:product_img_url)

  # -----------------------------
  # 3️⃣ 扩展 PostSerializer 让返回 JSON 包含自定义字段
  # -----------------------------
  add_to_serializer(:post, :product_category) { object.custom_fields["product_category"] }
  add_to_serializer(:post, :product_name)     { object.custom_fields["product_name"] }
  add_to_serializer(:post, :product_price)    { object.custom_fields["product_price"] }
  add_to_serializer(:post, :product_img_url)  { object.custom_fields["product_img_url"] }
end

