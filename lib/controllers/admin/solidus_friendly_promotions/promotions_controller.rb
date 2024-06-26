# frozen_string_literal: true

module SolidusFriendlyPromotions
  class PromotionsController < SolidusAdmin::BaseController
    include SolidusAdmin::ControllerHelpers::Search

    search_scope(:active, default: true, &:active)
    search_scope(:draft) { _1.where.not(id: _1.has_benefits.select(:id)) }
    search_scope(:future) { _1.has_benefits.where(starts_at: Time.current..) }
    search_scope(:expired) { _1.has_benefits.where(expires_at: ..Time.current) }
    search_scope(:all)

    def index
      promotions = apply_search_to(
        SolidusFriendlyPromotions::Promotion.order(id: :desc),
        param: :q
      )

      set_page_and_extract_portion_from(promotions)

      respond_to do |format|
        format.html { render component("promotions/index").new(page: @page) }
      end
    end

    def destroy
      @promotions = SolidusFriendlyPromotions::Promotion.where(id: params[:id])

      SolidusFriendlyPromotions::Promotion.transaction { @promotions.destroy_all }

      flash[:notice] = t(".success")
      redirect_back_or_to promotions_path, status: :see_other
    end

    private

    def load_promotion
      @promotion = SolidusFriendlyPromotions::Promotion.find_by!(number: params[:id])
      authorize! action_name, @promotion
    end

    def promotion_params
      params.require(:promotion).permit(:user_id, permitted_promotion_attributes)
    end
  end
end
