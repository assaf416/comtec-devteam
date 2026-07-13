class NotesController < ApplicationController
  before_action :set_note, only: %i[update destroy toggle_pin toggle_archive]

  def index
    @notes    = current_user.notes.active.sorted
    @archived = current_user.notes.archived.sorted
    @note     = current_user.notes.build
  end

  # Quick capture — a single field (title or body) is enough to create a note.
  def create
    @note = current_user.notes.build(note_params)
    if @note.save
      redirect_to notes_path, notice: t("notes.created")
    else
      @notes    = current_user.notes.active.sorted
      @archived = current_user.notes.archived.sorted
      render :index, status: :unprocessable_entity
    end
  end

  def update
    if @note.update(note_params)
      redirect_to notes_path, notice: t("notes.updated")
    else
      @notes    = current_user.notes.active.sorted
      @archived = current_user.notes.archived.sorted
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @note.destroy
    redirect_to notes_path, notice: t("notes.deleted")
  end

  def toggle_pin
    @note.update(pinned: !@note.pinned)
    redirect_to notes_path
  end

  def toggle_archive
    @note.update(archived: !@note.archived)
    redirect_to notes_path
  end

  private

  def set_note
    @note = current_user.notes.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:title, :body)
  end
end
