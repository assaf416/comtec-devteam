module ApplicationHelper
  MARKDOWN_RENDERER = Redcarpet::Markdown.new(
    Redcarpet::Render::HTML.new(hard_wrap: true, link_attributes: { target: "_blank", rel: "noopener" }),
    autolink: true, tables: true, fenced_code_blocks: true,
    strikethrough: true, highlight: true, no_intra_emphasis: true
  )

  def render_markdown(text)
    MARKDOWN_RENDERER.render(text.to_s).html_safe
  end

  # Build a Jitsi meeting room URL on the configured (self-hosted or public) server.
  def jitsi_room_url(room)
    base = ENV.fetch("JITSI_URL", "https://meet.jit.si").chomp("/")
    "#{base}/#{room}"
  end

  # Renders a circular avatar — Active Storage image or initials fallback.
  # size: pixel diameter (default 36)
  def user_avatar(user, size: 36, bg: "#4a90d9", css_class: "")
    shared_style = "width:#{size}px;height:#{size}px;border-radius:50%;flex-shrink:0;object-fit:cover;"

    if user&.avatar&.attached? && user.avatar.blob&.content_type&.start_with?("image/")
      if user.avatar.blob.content_type == "image/svg+xml"
        image_tag url_for(user.avatar),
                  style: "#{shared_style} display:block;",
                  class: css_class,
                  alt: user.display_name,
                  loading: "lazy"
      else
        image_tag user.avatar.variant(resize_to_fill: [ size * 2, size * 2 ]),
                  style: "#{shared_style} display:block;",
                  class: css_class,
                  alt: user.display_name,
                  loading: "lazy"
      end
    else
      initials = user ? user.initials : "?"
      content_tag(:div, initials,
        style: "#{shared_style} background:#{bg};color:#fff;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:#{size * 0.38}px;",
        class: css_class,
        title: user&.display_name)
    end
  end

  def flash_class(type)
    {
      "notice"  => "alert-success",
      "success" => "alert-success",
      "alert"   => "alert-danger",
      "error"   => "alert-danger",
      "warning" => "alert-warning",
      "info"    => "alert-info"
    }.fetch(type.to_s, "alert-info")
  end

  def status_tag(status)
    color = case status.to_s
    when "passed", "done", "succeeded", "merged" then "bg-success"
    when "failed", "blocked", "error"             then "bg-danger"
    when "running", "in_progress", "open"         then "bg-warning text-dark"
    when "cancelled", "closed", "rolled_back"     then "bg-secondary"
    when "pending"                                 then "bg-info text-dark"
    else "bg-secondary"
    end
    content_tag(:span, status.to_s.humanize, class: "badge #{color}")
  end

  def priority_tag(priority)
    color = case priority.to_s
    when "critical" then "bg-danger"
    when "high"     then "bg-warning text-dark"
    when "medium"   then "bg-info text-dark"
    else "bg-secondary"
    end
    content_tag(:span, t("tickets.priorities.#{priority}"), class: "badge #{color}")
  end

  def rtl?
    I18n.locale.to_s == "he"
  end

  def jitsi_url_for(room_name)
    base = ENV.fetch("JITSI_URL", "https://meet.jit.si")
    "#{base}/#{ERB::Util.url_encode(room_name)}"
  end

  # Renders a Bootstrap dropdown with a hamburger (⋮) trigger for table row actions.
  # Usage:
  #   actions_dropdown do |d|
  #     d.link "View", some_path, icon: "👁"
  #     d.link "Edit", edit_path, icon: "✏️"
  #     d.divider
  #     d.delete "Delete", some_path, confirm: "Are you sure?"
  #   end
  def actions_dropdown(&block)
    builder = ActionsDropdownBuilder.new(self)
    block.call(builder)
    id = "actions-#{SecureRandom.hex(4)}"
    align_class = rtl? ? "text-start" : "text-end"

    content_tag(:div, class: "dropdown #{align_class}") do
      button = content_tag(:button, "⋮",
        class: "btn btn-sm btn-outline-secondary dropdown-toggle actions-kebab",
        type: "button",
        id: id,
        data: { bs_toggle: "dropdown" },
        aria: { expanded: false })
      menu = content_tag(:ul, class: "dropdown-menu dropdown-menu-end shadow-sm", aria: { labelledby: id }) do
        safe_join(builder.items)
      end
      button + menu
    end
  end

  class ActionsDropdownBuilder
    attr_reader :items

    def initialize(helper)
      @helper = helper
      @items = []
    end

    def link(label, url, icon: nil, method: nil, **html_opts)
      # A non-GET "link" must submit a real form, otherwise it navigates as a
      # GET and 404s. Plain (GET) links stay as anchors.
      if method && method.to_sym != :get
        return @items << @helper.content_tag(:li, button_form(url, label, method: method, icon: icon))
      end

      link = @helper.link_to(url, class: "dropdown-item fs-7", **html_opts) do
        icon_html = icon ? @helper.content_tag(:span, icon, class: "me-2") : "".html_safe
        icon_html + label
      end
      @items << @helper.content_tag(:li, link)
    end

    def delete(label, url, confirm: nil)
      @items << @helper.content_tag(:li, button_form(url, label, method: :delete, icon: "🗑",
                                                     confirm: confirm, button_class: "text-danger"))
    end

    def button_action(label, url, method: :patch, confirm: nil, icon: nil)
      @items << @helper.content_tag(:li, button_form(url, label, method: method, icon: icon, confirm: confirm))
    end

    def divider
      @items << @helper.content_tag(:li, @helper.content_tag(:hr, nil, class: "dropdown-divider"))
    end

    private

    # Renders a state-changing dropdown action as a real <form> button. Using
    # button_to (rather than a link with data-turbo-method) guarantees the
    # correct HTTP verb is sent whether or not Turbo upgrades the request, so
    # actions like move-to-sprint never fall back to a GET and 404.
    def button_form(url, label, method:, icon: nil, confirm: nil, button_class: nil)
      form_data = {}
      form_data[:turbo_confirm] = confirm if confirm
      @helper.button_to(url,
        method: method,
        class: "dropdown-item fs-7 #{button_class}".strip,
        form: { class: "d-grid", data: form_data }) do
        icon_html = icon ? @helper.content_tag(:span, icon, class: "me-2") : "".html_safe
        icon_html + label.to_s
      end
    end
  end
end
