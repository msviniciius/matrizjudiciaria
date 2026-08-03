class LegalPublicationsController < ApplicationController
  before_action :set_legal_publication, only: :mark_read

  def index
    @filters = publication_filters
    @legal_publications = current_office
      .legal_publications
      .includes(legal_case: :client)
      .recent

    @legal_publications = @legal_publications.unread if @filters[:status] == "unread"
    @legal_publications = @legal_publications.read if @filters[:status] == "read"
    @legal_publications = @legal_publications.linked if @filters[:link] == "linked"
    @legal_publications = @legal_publications.unlinked if @filters[:link] == "unlinked"
    @legal_publications = search_publications(@legal_publications, @filters[:q]) if @filters[:q].present?
    @advanced_filters_open = @filters.values.any?(&:present?)
  end

  def mark_read
    @legal_publication.mark_read!
    redirect_to legal_publications_path, notice: "Publicação marcada como lida.", status: :see_other
  end

  private

  def set_legal_publication
    @legal_publication = current_office.legal_publications.find(params.expect(:id))
  end

  def publication_filters
    params.permit(:q, :status, :link)
  end

  def search_publications(scope, query)
    term = "%#{query.to_s.strip}%"
    scope.where(
      "COALESCE(legal_publications.title, '') ILIKE :term
       OR COALESCE(legal_publications.content, '') ILIKE :term
       OR COALESCE(legal_publications.process_number, '') ILIKE :term
       OR COALESCE(legal_publications.source, '') ILIKE :term
       OR COALESCE(legal_publications.journal_name, '') ILIKE :term",
      term: term
    )
  end
end
