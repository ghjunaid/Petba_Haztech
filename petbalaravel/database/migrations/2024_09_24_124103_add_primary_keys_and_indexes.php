<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up() {
        Schema::table('cities', function (Blueprint $table) {
            $table->integer('city_id', 50)->autoIncrement()->change();
        });

        // For table 'colors'
        Schema::table('colors', function (Blueprint $table) {
            $table->integer('id', 11)->autoIncrement()->change();
        });

        // For table 'donation'
        Schema::table('donation', function (Blueprint $table) {
            $table->integer('donation_id', 11)->autoIncrement()->change();
        });

        // For table 'foster'
        Schema::table('foster', function (Blueprint $table) {
            $table->integer('id', 11)->autoIncrement()->change();
        });

        // For table 'fosterFilterGroup'
        Schema::table('fosterFilterGroup', function (Blueprint $table) {
            $table->integer('id', 11)->autoIncrement()->change();
        });

        // For table 'fosterFilters'
        Schema::table('fosterFilters', function (Blueprint $table) {
            $table->integer('filter_id', 11)->autoIncrement()->change();
        });

        // For table 'foster_reviews'
        Schema::table('foster_reviews', function (Blueprint $table) {
            $table->integer('id', 11)->autoIncrement()->change();
        });

        // For table 'foster_to_filter'
        Schema::table('foster_to_filter', function (Blueprint $table) {
            $table->integer('id', 11)->autoIncrement()->change();
        });

        // For table 'friends'
        Schema::table('friends', function (Blueprint $table) {
            $table->integer('id', 11)->autoIncrement()->change();
        });

        // For table 'groomers'
        Schema::table('groomers', function (Blueprint $table) {
            $table->integer('id', 11)->autoIncrement()->change();
        });

        // For table 'grooming'
        Schema::table('grooming', function (Blueprint $table) {
            $table->integer('id', 11)->autoIncrement()->change();
        });

        // For table 'groomingFilterGroup'
        Schema::table('groomingFilterGroup', function (Blueprint $table) {
            $table->integer('id', 11)->autoIncrement()->change();
        });

        // For table 'groomingFilters'
        Schema::table('groomingFilters', function (Blueprint $table) {
            $table->integer('filter_id', 11)->autoIncrement()->change();
        });

        // For table 'grooming_reviews'
        Schema::table('grooming_reviews', function (Blueprint $table) {
            $table->integer('id', 11)->autoIncrement()->change();
        });

        // For table 'grooming_to_filter'
        Schema::table('grooming_to_filter', function (Blueprint $table) {
            $table->integer('id', 11)->autoIncrement()->change();
        });

        // For table 'interested'
        Schema::table('interested', function (Blueprint $table) {
            $table->integer('id', 11)->autoIncrement()->change();
        });

        // For table 'my_pets'
        Schema::table('my_pets', function (Blueprint $table) {
            $table->integer('pet_id', 11)->autoIncrement()->change();
        });

        // For table 'notification'
        Schema::table('notification', function (Blueprint $table) {
            $table->integer('id', 11)->autoIncrement()->change();
        });

        // For table 'oc_address'
        Schema::table('oc_address', function (Blueprint $table) {
            $table->integer('address_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_api'
        Schema::table('oc_api', function (Blueprint $table) {
            $table->integer('api_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_api_ip'
        Schema::table('oc_api_ip', function (Blueprint $table) {
            $table->integer('api_ip_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_api_session'
        Schema::table('oc_api_session', function (Blueprint $table) {
            $table->integer('api_session_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_attribute'
        Schema::table('oc_attribute', function (Blueprint $table) {
            $table->integer('attribute_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_attribute_group'
        Schema::table('oc_attribute_group', function (Blueprint $table) {
            $table->integer('attribute_group_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_banner'
        Schema::table('oc_banner', function (Blueprint $table) {
            $table->integer('banner_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_banner_image'
        Schema::table('oc_banner_image', function (Blueprint $table) {
            $table->integer('banner_image_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_cart'
        Schema::table('oc_cart', function (Blueprint $table) {
            $table->integer('cart_id', 11)->unsigned()->autoIncrement()->change();
        });

        // For table 'oc_category'
        Schema::table('oc_category', function (Blueprint $table) {
            $table->integer('category_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_country'
        Schema::table('oc_country', function (Blueprint $table) {
            $table->integer('country_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_coupon'
        Schema::table('oc_coupon', function (Blueprint $table) {
            $table->integer('coupon_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_coupon_history'
        Schema::table('oc_coupon_history', function (Blueprint $table) {
            $table->integer('coupon_history_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_coupon_product'
        Schema::table('oc_coupon_product', function (Blueprint $table) {
            $table->integer('coupon_product_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_currency'
        Schema::table('oc_currency', function (Blueprint $table) {
            $table->integer('currency_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_customer'
        Schema::table('oc_customer', function (Blueprint $table) {
            $table->integer('customer_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_customer_activity'
        Schema::table('oc_customer_activity', function (Blueprint $table) {
            $table->integer('customer_activity_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_customer_approval'
        Schema::table('oc_customer_approval', function (Blueprint $table) {
            $table->integer('customer_approval_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_customer_group'
        Schema::table('oc_customer_group', function (Blueprint $table) {
            $table->integer('customer_group_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_customer_history'
        Schema::table('oc_customer_history', function (Blueprint $table) {
            $table->integer('customer_history_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_customer_ip'
        Schema::table('oc_customer_ip', function (Blueprint $table) {
            $table->integer('customer_ip_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_customer_login'
        Schema::table('oc_customer_login', function (Blueprint $table) {
            $table->integer('customer_login_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_customer_reward'
        Schema::table('oc_customer_reward', function (Blueprint $table) {
            $table->integer('customer_reward_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_customer_transaction'
        Schema::table('oc_customer_transaction', function (Blueprint $table) {
            $table->integer('customer_transaction_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_custom_field'
        Schema::table('oc_custom_field', function (Blueprint $table) {
            $table->integer('custom_field_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_custom_field_value'
        Schema::table('oc_custom_field_value', function (Blueprint $table) {
            $table->integer('custom_field_value_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_download'
        Schema::table('oc_download', function (Blueprint $table) {
            $table->integer('download_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_event'
        Schema::table('oc_event', function (Blueprint $table) {
            $table->integer('event_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_extension'
        Schema::table('oc_extension', function (Blueprint $table) {
            $table->integer('extension_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_filter'
        Schema::table('oc_filter', function (Blueprint $table) {
            $table->integer('filter_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_filter_group'
        Schema::table('oc_filter_group', function (Blueprint $table) {
            $table->integer('filter_group_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_geo_zone'
        Schema::table('oc_geo_zone', function (Blueprint $table) {
            $table->integer('geo_zone_id', 11)->autoIncrement()->change();
        });

        // For table 'oc_information'
        Schema::table('oc_information', function (Blueprint $table) {
            $table->integer('information_id', 11)->autoIncrement()->change();
        });

        Schema::table('oc_journal3_blog_category', function (Blueprint $table) {
            $table->id('category_id')->change();
        });

        Schema::table('oc_journal3_blog_comments', function (Blueprint $table) {
            $table->id('comment_id')->change();
        });

        Schema::table('oc_journal3_blog_post', function (Blueprint $table) {
            $table->id('post_id')->change();
        });

        Schema::table('oc_journal3_layout', function (Blueprint $table) {
            $table->id('layout_id')->change();
        });

        Schema::table('oc_journal3_message', function (Blueprint $table) {
            $table->id('message_id')->change();
        });

        Schema::table('oc_journal3_module', function (Blueprint $table) {
            $table->id('module_id')->change();
        });

        Schema::table('oc_journal3_newsletter', function (Blueprint $table) {
            $table->id('newsletter_id')->change();
        });

        Schema::table('oc_journal3_skin', function (Blueprint $table) {
            $table->id('skin_id')->change();
        });

        Schema::table('oc_language', function (Blueprint $table) {
            $table->id('language_id')->change();
        });

        Schema::table('oc_layout', function (Blueprint $table) {
            $table->id('layout_id')->change();
        });

        Schema::table('oc_layout_module', function (Blueprint $table) {
            $table->id('layout_module_id')->change();
        });

        Schema::table('oc_layout_route', function (Blueprint $table) {
            $table->id('layout_route_id')->change();
        });

        Schema::table('oc_length_class', function (Blueprint $table) {
            $table->id('length_class_id')->change();
        });

        Schema::table('oc_location', function (Blueprint $table) {
            $table->id('location_id')->change();
        });

        Schema::table('oc_manufacturer', function (Blueprint $table) {
            $table->id('manufacturer_id')->change();
        });

        Schema::table('oc_marketing', function (Blueprint $table) {
            $table->id('marketing_id')->change();
        });

        Schema::table('oc_modification', function (Blueprint $table) {
            $table->id('modification_id')->change();
        });

        Schema::table('oc_module', function (Blueprint $table) {
            $table->id('module_id')->change();
        });

        Schema::table('oc_option', function (Blueprint $table) {
            $table->id('option_id')->change();
        });

        Schema::table('oc_option_value', function (Blueprint $table) {
            $table->id('option_value_id')->change();
        });

        Schema::table('oc_order', function (Blueprint $table) {
            $table->id('order_id')->change();
        });

        Schema::table('oc_order_history', function (Blueprint $table) {
            $table->id('order_history_id')->change();
        });

        Schema::table('oc_order_option', function (Blueprint $table) {
            $table->id('order_option_id')->change();
        });

        Schema::table('oc_order_product', function (Blueprint $table) {
            $table->id('order_product_id')->change();
        });

        Schema::table('oc_order_recurring', function (Blueprint $table) {
            $table->id('order_recurring_id')->change();
        });

        Schema::table('oc_order_recurring_transaction', function (Blueprint $table) {
            $table->id('order_recurring_transaction_id')->change();
        });

        Schema::table('oc_order_shipment', function (Blueprint $table) {
            $table->id('order_shipment_id')->change();
        });

        Schema::table('oc_order_status', function (Blueprint $table) {
            $table->id('order_status_id')->change();
        });

        Schema::table('oc_order_total', function (Blueprint $table) {
            $table->id('order_total_id')->change();
        });

        Schema::table('oc_order_voucher', function (Blueprint $table) {
            $table->id('order_voucher_id')->change();
        });

        Schema::table('oc_product', function (Blueprint $table) {
            $table->id('product_id')->change();
        });


        Schema::table('oc_product_description', function (Blueprint $table) {
            $table->id('product_id')->change();
        });

        Schema::table('oc_product_discount', function (Blueprint $table) {
            $table->id('product_discount_id')->change();
        });

        Schema::table('oc_product_filter', function (Blueprint $table) {
            $table->id('product_id')->change();
        });

        Schema::table('oc_product_image', function (Blueprint $table) {
            $table->id('product_image_id')->change();
        });

        Schema::table('oc_product_option', function (Blueprint $table) {
            $table->id('product_option_id')->change();
        });

        Schema::table('oc_product_option_value', function (Blueprint $table) {
            $table->id('product_option_value_id')->change();
        });

        Schema::table('oc_product_reward', function (Blueprint $table) {
            $table->id('product_reward_id')->change();
        });

        Schema::table('oc_product_special', function (Blueprint $table) {
            $table->id('product_special_id')->change();
        });

        Schema::table('oc_product_to_category', function (Blueprint $table) {
            $table->id('product_id')->change();
        });

        Schema::table('oc_recurring', function (Blueprint $table) {
            $table->id('recurring_id')->change();
        });

        Schema::table('oc_review', function (Blueprint $table) {
            $table->id('review_id')->change();
        });

        Schema::table('oc_return', function (Blueprint $table) {
            $table->id('return_id')->change();
        });

        Schema::table('oc_return_action', function (Blueprint $table) {
            $table->id('return_action_id')->change();
        });

        Schema::table('oc_return_history', function (Blueprint $table) {
            $table->id('return_history_id')->change();
        });

        Schema::table('oc_return_reason', function (Blueprint $table) {
            $table->id('return_reason_id')->change();
        });

        Schema::table('oc_return_status', function (Blueprint $table) {
            $table->id('return_status_id')->change();
        });

        Schema::table('oc_setting', function (Blueprint $table) {
            $table->id('setting_id')->change();
        });

        Schema::table('oc_stock_status', function (Blueprint $table) {
            $table->id('stock_status_id')->change();
        });

        Schema::table('oc_store', function (Blueprint $table) {
            $table->id('store_id')->change();
        });

        Schema::table('oc_tax_class', function (Blueprint $table) {
            $table->id('tax_class_id')->change();
        });

        Schema::table('oc_tax_rate', function (Blueprint $table) {
            $table->id('tax_rate_id')->change();
        });

        Schema::table('oc_tax_rule', function (Blueprint $table) {
            $table->id('tax_rule_id')->change();
        });

        Schema::table('oc_user', function (Blueprint $table) {
            $table->id('user_id')->change();
        });

        Schema::table('oc_user_group', function (Blueprint $table) {
            $table->id('user_group_id')->change();
        });

        Schema::table('oc_voucher', function (Blueprint $table) {
            $table->id('voucher_id')->change();
        });

        Schema::table('oc_voucher_history', function (Blueprint $table) {
            $table->id('voucher_history_id')->change();
        });

        Schema::table('oc_voucher_theme', function (Blueprint $table) {
            $table->id('voucher_theme_id')->change();
        });

        Schema::table('oc_weight_class', function (Blueprint $table) {
            $table->id('weight_class_id')->change();
        });

        Schema::table('oc_zone', function (Blueprint $table) {
            $table->id('zone_id')->change();
        });

        
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('cities', function (Blueprint $table) {
            $table->integer('city_id', 50)->change();
        });

        // For table 'colors'
        Schema::table('colors', function (Blueprint $table) {
            $table->integer('id', 11)->change();
        });

        // For table 'donation'
        Schema::table('donation', function (Blueprint $table) {
            $table->integer('donation_id', 11)->change();
        });

        // For table 'foster'
        Schema::table('foster', function (Blueprint $table) {
            $table->integer('id', 11)->change();
        });

        // For table 'fosterFilterGroup'
        Schema::table('fosterFilterGroup', function (Blueprint $table) {
            $table->integer('id', 11)->change();
        });

        // For table 'fosterFilters'
        Schema::table('fosterFilters', function (Blueprint $table) {
            $table->integer('filter_id', 11)->change();
        });

        // For table 'foster_reviews'
        Schema::table('foster_reviews', function (Blueprint $table) {
            $table->integer('id', 11)->change();
        });

        // For table 'foster_to_filter'
        Schema::table('foster_to_filter', function (Blueprint $table) {
            $table->integer('id', 11)->change();
        });

        // For table 'friends'
        Schema::table('friends', function (Blueprint $table) {
            $table->integer('id', 11)->change();
        });

        // For table 'groomers'
        Schema::table('groomers', function (Blueprint $table) {
            $table->integer('id', 11)->change();
        });

        // For table 'grooming'
        Schema::table('grooming', function (Blueprint $table) {
            $table->integer('id', 11)->change();
        });

        // For table 'groomingFilterGroup'
        Schema::table('groomingFilterGroup', function (Blueprint $table) {
            $table->integer('id', 11)->change();
        });

        // For table 'groomingFilters'
        Schema::table('groomingFilters', function (Blueprint $table) {
            $table->integer('filter_id', 11)->change();
        });

        // For table 'grooming_reviews'
        Schema::table('grooming_reviews', function (Blueprint $table) {
            $table->integer('id', 11)->change();
        });

        // For table 'grooming_to_filter'
        Schema::table('grooming_to_filter', function (Blueprint $table) {
            $table->integer('id', 11)->change();
        });

        // For table 'interested'
        Schema::table('interested', function (Blueprint $table) {
            $table->integer('id', 11)->change();
        });

        // For table 'my_pets'
        Schema::table('my_pets', function (Blueprint $table) {
            $table->integer('pet_id', 11)->change();
        });

        // For table 'notification'
        Schema::table('notification', function (Blueprint $table) {
            $table->integer('id', 11)->change();
        });

        // For table 'oc_address'
        Schema::table('oc_address', function (Blueprint $table) {
            $table->integer('address_id', 11)->change();
        });

        // For table 'oc_api'
        Schema::table('oc_api', function (Blueprint $table) {
            $table->integer('api_id', 11)->change();
        });

        // For table 'oc_api_ip'
        Schema::table('oc_api_ip', function (Blueprint $table) {
            $table->integer('api_ip_id', 11)->change();
        });

        // For table 'oc_api_session'
        Schema::table('oc_api_session', function (Blueprint $table) {
            $table->integer('api_session_id', 11)->change();
        });

        // For table 'oc_attribute'
        Schema::table('oc_attribute', function (Blueprint $table) {
            $table->integer('attribute_id', 11)->change();
        });

        // For table 'oc_attribute_group'
        Schema::table('oc_attribute_group', function (Blueprint $table) {
            $table->integer('attribute_group_id', 11)->change();
        });

        // For table 'oc_banner'
        Schema::table('oc_banner', function (Blueprint $table) {
            $table->integer('banner_id', 11)->change();
        });

        // For table 'oc_banner_image'
        Schema::table('oc_banner_image', function (Blueprint $table) {
            $table->integer('banner_image_id', 11)->change();
        });

        // For table 'oc_cart'
        Schema::table('oc_cart', function (Blueprint $table) {
            $table->integer('cart_id', 11)->unsigned()->change();
        });

        // For table 'oc_category'
        Schema::table('oc_category', function (Blueprint $table) {
            $table->integer('category_id', 11)->change();
        });

        // For table 'oc_country'
        Schema::table('oc_country', function (Blueprint $table) {
            $table->integer('country_id', 11)->change();
        });

        // For table 'oc_coupon'
        Schema::table('oc_coupon', function (Blueprint $table) {
            $table->integer('coupon_id', 11)->change();
        });

        // For table 'oc_coupon_history'
        Schema::table('oc_coupon_history', function (Blueprint $table) {
            $table->integer('coupon_history_id', 11)->change();
        });

        // For table 'oc_coupon_product'
        Schema::table('oc_coupon_product', function (Blueprint $table) {
            $table->integer('coupon_product_id', 11)->change();
        });

        // For table 'oc_currency'
        Schema::table('oc_currency', function (Blueprint $table) {
            $table->integer('currency_id', 11)->change();
        });

        // For table 'oc_customer'
        Schema::table('oc_customer', function (Blueprint $table) {
            $table->integer('customer_id', 11)->change();
        });

        // For table 'oc_customer_activity'
        Schema::table('oc_customer_activity', function (Blueprint $table) {
            $table->integer('customer_activity_id', 11)->change();
        });

        // For table 'oc_customer_approval'
        Schema::table('oc_customer_approval', function (Blueprint $table) {
            $table->integer('customer_approval_id', 11)->change();
        });

        // For table 'oc_customer_group'
        Schema::table('oc_customer_group', function (Blueprint $table) {
            $table->integer('customer_group_id', 11)->change();
        });

        // For table 'oc_customer_history'
        Schema::table('oc_customer_history', function (Blueprint $table) {
            $table->integer('customer_history_id', 11)->change();
        });

        // For table 'oc_customer_ip'
        Schema::table('oc_customer_ip', function (Blueprint $table) {
            $table->integer('customer_ip_id', 11)->change();
        });

        // For table 'oc_customer_login'
        Schema::table('oc_customer_login', function (Blueprint $table) {
            $table->integer('customer_login_id', 11)->change();
        });

        // For table 'oc_customer_reward'
        Schema::table('oc_customer_reward', function (Blueprint $table) {
            $table->integer('customer_reward_id', 11)->change();
        });

        // For table 'oc_customer_search'
        Schema::table('oc_customer_search', function (Blueprint $table) {
            $table->integer('customer_search_id', 11)->change();
        });

        // For table 'oc_customer_transaction'
        Schema::table('oc_customer_transaction', function (Blueprint $table) {
            $table->integer('customer_transaction_id', 11)->change();
        });

        // For table 'oc_custom_field'
        Schema::table('oc_custom_field', function (Blueprint $table) {
            $table->integer('custom_field_id', 11)->change();
        });

        // For table 'oc_custom_field_value'
        Schema::table('oc_custom_field_value', function (Blueprint $table) {
            $table->integer('custom_field_value_id', 11)->change();
        });

        // For table 'oc_download'
        Schema::table('oc_download', function (Blueprint $table) {
            $table->integer('download_id', 11)->change();
        });

        // For table 'oc_event'
        Schema::table('oc_event', function (Blueprint $table) {
            $table->integer('event_id', 11)->change();
        });

        // For table 'oc_extension'
        Schema::table('oc_extension', function (Blueprint $table) {
            $table->integer('extension_id', 11)->change();
        });

        // For table 'oc_filter'
        Schema::table('oc_filter', function (Blueprint $table) {
            $table->integer('filter_id', 11)->change();
        });

        // For table 'oc_filter_group'
        Schema::table('oc_filter_group', function (Blueprint $table) {
            $table->integer('filter_group_id', 11)->change();
        });

        // For table 'oc_geo_zone'
        Schema::table('oc_geo_zone', function (Blueprint $table) {
            $table->integer('geo_zone_id', 11)->change();
        });

        // For table 'oc_information'
        Schema::table('oc_information', function (Blueprint $table) {
            $table->integer('information_id', 11)->change();
        });

        Schema::table('oc_journal3_blog_category', function (Blueprint $table) {
            $table->integer('category_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_journal3_blog_category_to_layout', function (Blueprint $table) {
            $table->integer('category_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_journal3_blog_comments', function (Blueprint $table) {
            $table->integer('comment_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_journal3_blog_post', function (Blueprint $table) {
            $table->integer('post_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_journal3_blog_post_to_layout', function (Blueprint $table) {
            $table->integer('post_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_journal3_layout', function (Blueprint $table) {
            $table->integer('layout_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_journal3_message', function (Blueprint $table) {
            $table->integer('message_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_journal3_module', function (Blueprint $table) {
            $table->integer('module_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_journal3_newsletter', function (Blueprint $table) {
            $table->integer('newsletter_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_journal3_skin', function (Blueprint $table) {
            $table->integer('skin_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_language', function (Blueprint $table) {
            $table->integer('language_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_layout', function (Blueprint $table) {
            $table->integer('layout_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_layout_module', function (Blueprint $table) {
            $table->integer('layout_module_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_layout_route', function (Blueprint $table) {
            $table->integer('layout_route_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_length_class', function (Blueprint $table) {
            $table->integer('length_class_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_location', function (Blueprint $table) {
            $table->integer('location_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_manufacturer', function (Blueprint $table) {
            $table->integer('manufacturer_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_marketing', function (Blueprint $table) {
            $table->integer('marketing_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_modification', function (Blueprint $table) {
            $table->integer('modification_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_module', function (Blueprint $table) {
            $table->integer('module_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_option', function (Blueprint $table) {
            $table->integer('option_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_option_value', function (Blueprint $table) {
            $table->integer('option_value_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_order', function (Blueprint $table) {
            $table->integer('order_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_order_history', function (Blueprint $table) {
            $table->integer('order_history_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_order_option', function (Blueprint $table) {
            $table->integer('order_option_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_order_product', function (Blueprint $table) {
            $table->integer('order_product_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_order_recurring', function (Blueprint $table) {
            $table->integer('order_recurring_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_order_recurring_transaction', function (Blueprint $table) {
            $table->integer('order_recurring_transaction_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_order_shipment', function (Blueprint $table) {
            $table->integer('order_shipment_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_order_status', function (Blueprint $table) {
            $table->integer('order_status_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_order_total', function (Blueprint $table) {
            $table->integer('order_total_id', 10)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_order_voucher', function (Blueprint $table) {
            $table->integer('order_voucher_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_product', function (Blueprint $table) {
            $table->integer('product_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_product_discount', function (Blueprint $table) {
            $table->integer('product_discount_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_product_image', function (Blueprint $table) {
            $table->integer('product_image_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_product_option', function (Blueprint $table) {
            $table->integer('product_option_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_product_option_value', function (Blueprint $table) {
            $table->integer('product_option_value_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_product_reward', function (Blueprint $table) {
            $table->integer('product_reward_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_product_special', function (Blueprint $table) {
            $table->integer('product_special_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_razorpay_plans', function (Blueprint $table) {
            $table->integer('entity_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_razorpay_subscriptions', function (Blueprint $table) {
            $table->integer('entity_id', 10)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_recurring', function (Blueprint $table) {
            $table->integer('recurring_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_return', function (Blueprint $table) {
            $table->integer('return_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_return_action', function (Blueprint $table) {
            $table->integer('return_action_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_return_history', function (Blueprint $table) {
            $table->integer('return_history_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_return_reason', function (Blueprint $table) {
            $table->integer('return_reason_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_return_status', function (Blueprint $table) {
            $table->integer('return_status_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_review', function (Blueprint $table) {
            $table->integer('review_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_seo_url', function (Blueprint $table) {
            $table->integer('seo_url_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_setting', function (Blueprint $table) {
            $table->integer('setting_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_statistics', function (Blueprint $table) {
            $table->integer('statistics_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_store', function (Blueprint $table) {
            $table->integer('store_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_subscription', function (Blueprint $table) {
            $table->integer('subscription_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_tax_class', function (Blueprint $table) {
            $table->integer('tax_class_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_tax_rate', function (Blueprint $table) {
            $table->integer('tax_rate_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_tax_rule', function (Blueprint $table) {
            $table->integer('tax_rule_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_user', function (Blueprint $table) {
            $table->integer('user_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_user_group', function (Blueprint $table) {
            $table->integer('user_group_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_voucher', function (Blueprint $table) {
            $table->integer('voucher_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_voucher_history', function (Blueprint $table) {
            $table->integer('voucher_history_id', 11)->unsigned()->autoIncrement()->change();
        });

        Schema::table('oc_voucher_theme', function (Blueprint $table) {
            $table->integer('voucher_theme_id', 11)->unsigned()->autoIncrement()->change();
        });
    }
};
