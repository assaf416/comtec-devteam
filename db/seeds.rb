# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding..."

# ─────────────────────────────────────────────────────────────────
# Helper: attach a fake face photo as avatar
# Uses i.pravatar.cc for deterministic face images per user.
# ─────────────────────────────────────────────────────────────────
require "open-uri"

# Map each user to a specific pravatar image ID for consistency.
# IDs 1-70 are available on i.pravatar.cc.
# Real user avatars now come from the local docs/users-icons/ folder (no network).
USER_ICON_DIR   = Rails.root.join("docs/users-icons")
USER_ICON_FILES = Dir[USER_ICON_DIR.join("*.{jpg,jpeg,png}")].sort.freeze

# Stable per-person assignment so a known teammate keeps the same face on reseed.
AVATAR_FACE_BY_EMAIL = {
  "assaf@devteam.local"  => "face11.jpg",
  "yael@devteam.local"   => "face5.jpg",
  "noam@devteam.local"   => "face12.jpg",
  "dana@devteam.local"   => "face9.jpg",
  "oren@devteam.local"   => "face14.jpg",
  "michal@devteam.local" => "face2.jpg",
  "tal@devteam.local"    => "face6.jpg",
  "avi@devteam.local"    => "face7.jpg"
}.freeze

def attach_face_avatar(user, index)
  return if USER_ICON_FILES.empty?

  # Seed data owns the avatar — replace whatever is there with a local icon.
  user.avatar.purge if user.avatar.attached?

  mapped = AVATAR_FACE_BY_EMAIL[user.email]
  path   = mapped && USER_ICON_DIR.join(mapped)
  path   = nil unless path && File.exist?(path)
  path ||= USER_ICON_FILES[index % USER_ICON_FILES.size]

  user.avatar.attach(
    io:           File.open(path),
    filename:     "#{user.display_name.parameterize}-avatar#{File.extname(path)}",
    content_type: "image/jpeg"
  )
rescue StandardError => e
  puts "    ⚠ Could not attach local avatar for #{user.display_name}: #{e.message}"
end

# ─────────────────────────────────────────────────────────────────
#   Internal users (developers, leads, admin)
# ─────────────────────────────────────────────────────────────────
users_data = [
  { name: "Assaf Goldstein",   email: "assaf@devteam.local",   role: :admin           },
  { name: "Yael Cohen",        email: "yael@devteam.local",    role: :team_lead        },
  { name: "Noam Levi",         email: "noam@devteam.local",    role: :developer        },
  { name: "Dana Mizrahi",      email: "dana@devteam.local",    role: :developer        },
  { name: "Oren Shapiro",      email: "oren@devteam.local",    role: :developer        },
  { name: "Michal Ben-David",  email: "michal@devteam.local",  role: :qa               },
  { name: "Tal Katz",          email: "tal@devteam.local",     role: :project_manager  },
  { name: "Avi Peretz",        email: "avi@devteam.local",     role: :developer        }
]

users = users_data.map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.name     = attrs[:name]
    u.role     = attrs[:role]
    u.password = "password123"
    u.preferred_language = :he
  end
end

# All users default to Hebrew — enforce on reseed for pre-existing records too.
users.each { |u| u.update!(preferred_language: :he) unless u.lang_he? }

puts "  ✓ #{users.size} internal users (default language: Hebrew)"

# Attach face photo avatars to users
ActiveStorage::Current.url_options = { host: "localhost", port: 3000 }
users.each_with_index do |u, i|
  Rails.application.config.active_job.queue_adapter = :inline
  attach_face_avatar(u, i)
end
puts "  ✓ face photo avatars attached"

# ─────────────────────────────────────────────────────────────────
# Customers (portal accounts — parent of CustomerUser)
# ─────────────────────────────────────────────────────────────────
clients_data = [
  { name: "John Smith",    company: "Acme Corp",        email: "contact@acme.example",   phone: "+1-555-0101", contact_person: "John Smith"    },
  { name: "Sarah Connor",  company: "Globex Solutions",  email: "info@globex.example",    phone: "+1-555-0202", contact_person: "Sarah Connor"  },
  { name: "Bill Lumbergh", company: "Initech Ltd",       email: "hello@initech.example",  phone: "+1-555-0303", contact_person: "Bill Lumbergh" }
]

clients = clients_data.map do |attrs|
  Customer.find_or_create_by!(email: attrs[:email]) do |c|
    c.name           = attrs[:name]
    c.company        = attrs[:company]
    c.phone          = attrs[:phone]
    c.contact_person = attrs[:contact_person]
    c.active         = true
  end
end

puts "  ✓ #{clients.size} customers"

# ─────────────────────────────────────────────────────────────────
# Customer portal users (one or two per client)
# ─────────────────────────────────────────────────────────────────
customer_users_data = [
  { name: "John Smith",     email: "john@acme.example",       client: clients[0] },
  { name: "Amy Johnson",    email: "amy@acme.example",        client: clients[0] },
  { name: "Sarah Connor",   email: "sarah@globex.example",    client: clients[1] },
  { name: "Miles Dyson",    email: "miles@globex.example",    client: clients[1] },
  { name: "Bill Lumbergh",  email: "bill@initech.example",    client: clients[2] }
]

customer_users = customer_users_data.map do |attrs|
  CustomerUser.find_or_create_by!(email: attrs[:email]) do |cu|
    cu.name        = attrs[:name]
    cu.customer    = attrs[:client]
    cu.password    = "password123"
    cu.password_confirmation = "password123"
  end
end

puts "  ✓ #{customer_users.size} customer portal users"

# ─────────────────────────────────────────────────────────────────
# Projects  (5 real projects from the team email + this app)
# ─────────────────────────────────────────────────────────────────
projects_data = [
  {
    name:           "Print Server / TDI",
    description:    "Windows print server and TDI print management system. " \
                    "Handles print queue management, driver distribution, and " \
                    "enterprise printer configuration.",
    tech_stack:     "C# .NET 4.8.1, VB.net, Windows Print Spooler, WinForms",
    repo_url:       "https://github.com/assaf416/print-server-tdi",
    default_branch: "main",
    active:         true
  },
  {
    name:           "TDI2",
    description:    "Next-generation TDI platform built on ASP.NET MVC Core 10. " \
                    "Multi-threaded order processing with RabbitMQ messaging, " \
                    "Entity Framework Core ORM, and Serilog structured logging.",
    tech_stack:     "ASP.NET MVC Core 10, Visual Studio 2026, IIS, Razor Pages, " \
                    "NuGet, RabbitMQ, EntityFrameworkCore, Serilog, SQL Server, " \
                    "JavaScript, HTML, CSS, Bootstrap, JSON/XML, NUnit, Multithread",
    repo_url:       "https://github.com/assaf416/tdi2",
    default_branch: "main",
    active:         true
  },
  {
    name:           "Digital Internet Services",
    description:    "Customer-facing web portal with Vue 3 SPA frontend and " \
                    "NestJS API backend. Deployed using Docker Windows Containers " \
                    "with SQL Server persistence.",
    tech_stack:     "Vue 3 (Composition API + TypeScript), Vite, NestJS (Node.js), " \
                    "SQL Server, Docker (Windows Containers)",
    repo_url:       "https://github.com/assaf416/digital-internet-services",
    default_branch: "main",
    active:         true
  },
  {
    name:           "Work Management System",
    description:    "Internal work-item tracking platform. Next.js 16 frontend " \
                    "running on Bun runtime with PostgreSQL 16 storage and " \
                    "Jenkins CI/CD pipelines.",
    tech_stack:     "Next.js 16, TypeScript, Bun (runtime), PostgreSQL 16, Jenkins",
    repo_url:       "https://github.com/assaf416/work-management-system",
    default_branch: "main",
    active:         true
  },
  {
    name:           "DevTeam Hub",
    description:    "This application. Internal DevOps dashboard aggregating CI, " \
                    "deployments, pull requests, tickets, and team communication " \
                    "in a single Slack-style interface.",
    tech_stack:     "Rails 8.1, Ruby 3.4, SQLite3, Hotwire (Turbo + Stimulus), " \
                    "Bulma CSS, Devise, Pundit, ActiveStorage",
    repo_url:       "https://github.com/assaf416/dev-team-hub",
    default_branch: "main",
    active:         true
  }
]

projects = projects_data.map do |attrs|
  Project.find_or_create_by!(name: attrs[:name]) do |p|
    p.assign_attributes(attrs)
  end
end

puts "  ✓ #{projects.size} projects (#{projects.count(&:active?)} active)"

# ─────────────────────────────────────────────────────────────────
# Project memberships
# ─────────────────────────────────────────────────────────────────
admin      = users.find { |u| u.admin? }
team_lead  = users.find { |u| u.team_lead? }
developers = users.select { |u| u.developer? }  # noam, dana, oren, avi
qa_user    = users.find { |u| u.qa? }
pm_user    = users.find { |u| u.project_manager? }

noam, dana, oren, avi = developers

memberships = [
  # Print Server / TDI
  { project: projects[0], user: team_lead, role: :lead      },
  { project: projects[0], user: noam,      role: :developer },
  { project: projects[0], user: dana,      role: :developer },
  { project: projects[0], user: qa_user,   role: :qa        },

  # TDI2
  { project: projects[1], user: team_lead, role: :lead      },
  { project: projects[1], user: noam,      role: :developer },
  { project: projects[1], user: dana,      role: :developer },
  { project: projects[1], user: oren,      role: :developer },
  { project: projects[1], user: avi,       role: :developer },
  { project: projects[1], user: qa_user,   role: :qa        },

  # Digital Internet Services
  { project: projects[2], user: team_lead, role: :lead      },
  { project: projects[2], user: noam,      role: :developer },
  { project: projects[2], user: dana,      role: :developer },
  { project: projects[2], user: oren,      role: :developer },
  { project: projects[2], user: avi,       role: :developer },
  { project: projects[2], user: qa_user,   role: :qa        },

  # Work Management System
  { project: projects[3], user: pm_user,   role: :lead      },
  { project: projects[3], user: noam,      role: :developer },
  { project: projects[3], user: dana,      role: :developer },
  { project: projects[3], user: oren,      role: :developer },
  { project: projects[3], user: avi,       role: :developer },
  { project: projects[3], user: qa_user,   role: :qa        },

  # DevTeam Hub
  { project: projects[4], user: admin,     role: :lead      },
  { project: projects[4], user: team_lead, role: :developer },
  { project: projects[4], user: noam,      role: :developer },
  { project: projects[4], user: dana,      role: :developer },
  { project: projects[4], user: qa_user,   role: :qa        }
]

memberships.each do |m|
  ProjectMembership.find_or_create_by!(project: m[:project], user: m[:user]) do |pm|
    pm.role = m[:role]
  end
end

puts "  ✓ #{memberships.size} project memberships"

# ─────────────────────────────────────────────────────────────────
# Chat rooms
# ─────────────────────────────────────────────────────────────────
chat_rooms_data = [
  { name: "general",   description: "Company-wide announcements and chat",        room_type: :general,      project: nil          },
  { name: "random",    description: "Off-topic and fun stuff",                    room_type: :general,      project: nil          },
  { name: "incidents", description: "Production incident coordination",           room_type: :incident,     project: nil          },
  { name: "releases",  description: "Release announcements",                      room_type: :announcement, project: nil          },
  { name: "tdi",       description: "Print Server / TDI day-to-day discussion",  room_type: :project_room, project: projects[0]  },
  { name: "tdi2",      description: "TDI2 team channel",                         room_type: :project_room, project: projects[1]  },
  { name: "dis",       description: "Digital Internet Services channel",         room_type: :project_room, project: projects[2]  },
  { name: "wms",       description: "Work Management System channel",            room_type: :project_room, project: projects[3]  },
  { name: "devteam",   description: "DevTeam Hub dev channel",                   room_type: :project_room, project: projects[4]  }
]

chat_rooms_data.each do |attrs|
  ChatRoom.find_or_create_by!(name: attrs[:name]) do |r|
    r.description = attrs[:description]
    r.room_type   = attrs[:room_type]
    r.archived    = false
    r.project     = attrs[:project] if attrs[:project]
  end
end

puts "  ✓ #{chat_rooms_data.size} chat rooms"

# ─────────────────────────────────────────────────────────────────
# Demo project chat conversations — so the per-project Chat page has
# something to look at, including one image and one file attachment.
# ─────────────────────────────────────────────────────────────────
require "tempfile"

# Draw a small architecture-diagram PNG with ImageMagick. PNG (unlike SVG) is
# served inline by Active Storage, so it renders as an image in the chat.
# Returns a Tempfile, or nil if ImageMagick isn't available.
def project_chat_diagram_png(title)
  file = Tempfile.new([ "chat-diagram", ".png" ])
  file.close
  system(
    "convert", "-size", "360x200", "xc:#eef4fb",
    "-fill", "#4a90d9", "-draw", "roundrectangle 20,40 140,92 8,8",
    "-fill", "#20c997", "-draw", "roundrectangle 220,40 340,92 8,8",
    "-fill", "#7b68ee", "-draw", "roundrectangle 120,130 240,182 8,8",
    "-gravity", "NorthWest", "-fill", "#ffffff", "-pointsize", "12",
    "-annotate", "+58+62", "Frontend",
    "-annotate", "+264+62", "API",
    "-annotate", "+150+152", "Database",
    "-gravity", "North", "-fill", "#333333", "-pointsize", "13",
    "-annotate", "+0+8", title,
    file.path,
    exception: true
  )
  file
rescue StandardError => e
  puts "    ⚠ Could not generate chat diagram (#{e.message}) — skipping image"
  nil
end

ChatMessage.skip_broadcasts = true
projects.each do |project|
  room = project.chat_rooms.active.order(:created_at, :id).first
  next unless room
  next if room.chat_messages.exists?  # idempotent — don't duplicate on re-seed

  members = project.members.to_a
  members = users.first(4) if members.empty?
  who     = ->(i) { members[i % members.size] }

  ticket = Ticket.where(project: project).order(:id).first
  ref    = ticket ? "#T-#{ticket.id}" : "הכרטיס הראשון"

  scripted = [
    { user: who.(0), body: "בוקר טוב לכולם 👋 נתחיל את השבוע עם סנכרון קצר על #{project.name}.",              at: 2.days.ago.change(hour: 9, min: 0) },
    { user: who.(1), body: "אני על #{ref} — מקווה לסיים היום את הפיתוח ולהעביר ל-review.",                     at: 2.days.ago.change(hour: 9, min: 12) },
    { user: who.(0), body: "מצרף את דיאגרמת הארכיטקטורה שדיברנו עליה 👇",                                        at: 2.days.ago.change(hour: 10, min: 5), image: true },
    { user: who.(2), body: "תודה! אני מוסיף את סיכום הפגישה כקובץ להורדה.",                                       at: 1.day.ago.change(hour: 11, min: 20), file: true },
    { user: who.(1), body: "פתחתי PR — מוזמנים להסתכל כשמתפנה 🙏",                                               at: 1.day.ago.change(hour: 15, min: 30) },
    { user: who.(3), body: "עברתי על ה-QA, נראה טוב. יש הערה קטנה על edge case שאעלה בכרטיס.",                   at: Time.current.change(hour: 8, min: 45) },
    { user: who.(0), body: "מצוין, ממשיכים 🚀",                                                                   at: Time.current.change(hour: 9, min: 5) }
  ]

  scripted.each do |m|
    msg = room.chat_messages.build(user: m[:user], body: m[:body], created_at: m[:at])
    if m[:image]
      png = project_chat_diagram_png("#{project.name} — Architecture")
      msg.files.attach(io: File.open(png.path), filename: "architecture.png", content_type: "image/png") if png
    elsif m[:file]
      notes = "Meeting notes — #{project.name}\n\n" \
              "- החלטה: להתקדם לפי התכנון הנוכחי\n" \
              "- אחראי פיתוח: #{who.(1).display_name}\n" \
              "- יעד: סוף השבוע\n"
      msg.files.attach(
        io:           StringIO.new(notes),
        filename:     "meeting-notes.txt",
        content_type: "text/plain"
      )
    end
    msg.save!
  end
end
ChatMessage.skip_broadcasts = false
puts "  ✓ demo chat conversations seeded for #{projects.size} projects"

# ─────────────────────────────────────────────────────────────────
# Tickets / Stories
# Each entry: project, kind, level, title, description,
#             status, priority, owner, assignee,
#             dev_estimate_hours, tester_estimate_hours, actual_hours,
#             how_to_reproduce (optional — bugs/hotfixes),
#             pr_number (optional), pr_url (optional),
#             attach_spec (true = attach a spec/design document)
# ─────────────────────────────────────────────────────────────────
tickets_data = [
  # ── Print Server / TDI ───────────────────────────────────────────
  {
    project:               projects[0],
    kind:           :story,
    level:                 :complex,
    title:                 "Add PDF export for print queue jobs",
    description:           "Allow operators to export the current print queue as a PDF report " \
                           "including job ID, document name, page count, and submission time. " \
                           "The export should support filtering by printer and date range.",
    status:                :in_progress,
    priority:              :medium,
    owner:                 team_lead,
    assignee:              noam,
    dev_estimate_hours:    16.0,
    tester_estimate_hours: 4.0,
    actual_hours:          "2d 2h",
    attach_spec:           true
  },
  {
    project:               projects[0],
    kind:           :story,
    level:                 :moderate,
    title:                 "Support duplex printing profiles per printer",
    description:           "Add per-printer duplex profile configuration. Operators should be " \
                           "able to define default duplex mode (none, long-edge, short-edge) " \
                           "per printer. Profile must persist across server restarts.",
    status:                :backlog,
    priority:              :low,
    owner:                 pm_user,
    assignee:              nil,
    dev_estimate_hours:    8.0,
    tester_estimate_hours: 2.0,
    actual_hours:          nil,
    attach_spec:           true
  },
  {
    project:               projects[0],
    kind:           :bug_fix,
    level:                 :complex,
    how_to_reproduce:      "1. Connect a printer and start a multi-page print job\n2. Disconnect the printer's network cable mid-job\n3. Observe: job stays in 'Sending' status indefinitely\n4. Expected: job marked 'Failed' after retry timeout with configurable backoff",
    title:                 "Print jobs stuck in queue after network timeout",
    description:           "When the network connection to a printer is lost mid-job, the print " \
                           "spooler does not recover — jobs remain in the queue with status " \
                           "'Sending' indefinitely. Expected: auto-retry with configurable " \
                           "backoff, job marked 'Failed' after max retries.",
    status:                :open,
    priority:              :critical,
    owner:                 team_lead,
    assignee:              dana,
    dev_estimate_hours:    4.0,
    tester_estimate_hours: 1.0,
    actual_hours:          "5h",
    attach_spec:           false
  },
  {
    project:               projects[0],
    kind:           :bug_fix,
    level:                 :simple,
    how_to_reproduce:      "1. Set Windows locale to he-IL\n2. Open the print queue manager\n3. Add a print job for any document\n4. Observe: paper size defaults to Letter (8.5x11)\n5. Expected: paper size should default to A4 for he-IL locale",
    title:                 "Wrong paper size selected for Hebrew locale",
    description:           "When the system locale is set to he-IL, the default paper size " \
                           "falls back to Letter instead of A4. Root cause is likely a missing " \
                           "locale mapping in PaperSizeHelper.vb.",
    status:                :in_review,
    priority:              :high,
    owner:                 qa_user,
    assignee:              oren,
    dev_estimate_hours:    6.0,
    tester_estimate_hours: 2.0,
    actual_hours:          "7h",
    pr_number:             12,
    pr_url:                "https://github.com/assaf416/print-server-tdi/pulls/12",
    attach_spec:           false
  },
  {
    project:               projects[0],
    kind:           :meta_story,
    level:                 :simple,
    title:                 "Upgrade .NET runtime from 4.8.0 to 4.8.1",
    description:           "Update project target framework to .NET 4.8.1. Run full regression " \
                           "suite after upgrade. Update NuGet dependencies to compatible versions. " \
                           "Test on Windows Server 2019 and 2022.",
    status:                :done,
    priority:              :medium,
    owner:                 admin,
    assignee:              avi,
    dev_estimate_hours:    8.0,
    tester_estimate_hours: 8.0,
    actual_hours:          "1d 1h",
    attach_spec:           false
  },

  # ── TDI2 ─────────────────────────────────────────────────────────
  {
    project:               projects[1],
    kind:           :story,
    level:                 :complex,
    title:                 "Implement RabbitMQ dead-letter exchange for failed message retry",
    description:           "Configure a dead-letter exchange (DLX) on the order-processing queue. " \
                           "Messages that fail after 3 attempts should be routed to a DLX with a " \
                           "30-minute TTL before re-queuing. Add Serilog events for each DLX routing.",
    status:                :in_progress,
    priority:              :high,
    owner:                 team_lead,
    assignee:              noam,
    dev_estimate_hours:    24.0,
    tester_estimate_hours: 8.0,
    actual_hours:          "3d 6h",
    attach_spec:           true
  },
  {
    project:               projects[1],
    kind:           :story,
    level:                 :simple,
    title:                 "Add Serilog structured logging to all MVC controllers",
    description:           "Replace Console.WriteLine / Debug.WriteLine calls with Serilog " \
                           "ILogger<T> structured logging. Include request correlation ID " \
                           "(from X-Correlation-ID header) in every log entry. Configure " \
                           "Serilog sinks: File (rolling daily) + Application Insights.",
    status:                :done,
    priority:              :medium,
    owner:                 pm_user,
    assignee:              dana,
    dev_estimate_hours:    12.0,
    tester_estimate_hours: 4.0,
    actual_hours:          "10h",
    attach_spec:           false
  },
  {
    project:               projects[1],
    kind:           :story,
    level:                 :expert,
    title:                 "Migrate data layer to EntityFrameworkCore 9 code-first",
    description:           "Replace the legacy LINQ-to-SQL layer with EF Core 9 code-first " \
                           "migrations. Map all existing stored procedures to EF Core raw SQL " \
                           "calls or equivalent LINQ expressions. Target SQL Server 2022 " \
                           "compatibility level 160.",
    status:                :backlog,
    priority:              :high,
    owner:                 admin,
    assignee:              nil,
    dev_estimate_hours:    32.0,
    tester_estimate_hours: 16.0,
    attach_spec:           true
  },
  {
    project:               projects[1],
    kind:           :bug_fix,
    level:                 :expert,
    how_to_reproduce:      "1. Run OrderProcessor load test with 60+ concurrent threads\n2. Submit 100 identical order IDs simultaneously\n3. Check the database for duplicate Order records\n4. Observe: same order processed more than once, creating duplicate invoices\n5. Expected: each order processed exactly once (idempotent)",
    title:                 "Race condition in multi-threaded order processor",
    description:           "Under high load (>50 concurrent threads) the OrderProcessor " \
                           "occasionally processes the same order twice, resulting in duplicate " \
                           "invoices. Suspected cause: missing lock around order-status read-then-" \
                           "update. Needs a distributed lock via SQL Server application locks.",
    status:                :in_review,
    priority:              :critical,
    owner:                 qa_user,
    assignee:              oren,
    dev_estimate_hours:    16.0,
    tester_estimate_hours: 8.0,
    actual_hours:          "18h",
    pr_number:             34,
    pr_url:                "https://github.com/assaf416/tdi2/pulls/34",
    attach_spec:           false
  },
  {
    project:               projects[1],
    kind:           :bug_fix,
    level:                 :complex,
    how_to_reproduce:      "1. Log in as a tenant with >500k orders\n2. Navigate to Reports → Monthly Revenue\n3. Select any month with full data\n4. Observe: request times out after 30 seconds\n5. Run EXPLAIN on generated SQL — full table scan on Orders table confirmed",
    title:                 "SQL Server query timeout on large report generation",
    description:           "The monthly revenue report times out (30 s) for tenants with " \
                           ">500k orders. The query performs a full table scan on Orders " \
                           "because the WHERE clause casts the date column. Fix: add a " \
                           "computed persisted column + filtered index.",
    status:                :open,
    priority:              :high,
    owner:                 team_lead,
    assignee:              avi,
    dev_estimate_hours:    8.0,
    tester_estimate_hours: 4.0,
    actual_hours:          "9h",
    attach_spec:           false
  },

  # ── Digital Internet Services ─────────────────────────────────────
  {
    project:               projects[2],
    kind:           :story,
    level:                 :complex,
    title:                 "Build Vue 3 Composition API client statistics dashboard",
    description:           "Create a multi-panel statistics dashboard using Vue 3 Composition " \
                           "API + TypeScript. Panels: active sessions, bandwidth usage, top " \
                           "routes, error rate. Data sourced from NestJS /api/stats endpoints. " \
                           "Use Pinia for state management and Chart.js for visualisations.",
    status:                :in_progress,
    priority:              :high,
    owner:                 team_lead,
    assignee:              noam,
    dev_estimate_hours:    40.0,
    tester_estimate_hours: 16.0,
    actual_hours:          "4d 4h",
    attach_spec:           true
  },
  {
    project:               projects[2],
    kind:           :story,
    level:                 :complex,
    title:                 "Configure Docker Windows Container CI/CD deployment pipeline",
    description:           "Build a Docker Windows Container image for the NestJS API. " \
                           "Define multi-stage Dockerfile (build → runtime). Configure the " \
                           "Jenkins pipeline to: build image, push to internal registry, " \
                           "deploy to staging via docker service update.",
    status:                :backlog,
    priority:              :medium,
    owner:                 pm_user,
    assignee:              nil,
    dev_estimate_hours:    24.0,
    tester_estimate_hours: 8.0,
    attach_spec:           true
  },
  {
    project:               projects[2],
    kind:           :story,
    level:                 :complex,
    title:                 "NestJS JWT authentication with refresh token rotation",
    description:           "Implement JWT access + refresh token flow in the NestJS AuthModule. " \
                           "Access token TTL: 15 min. Refresh token TTL: 7 days with rotation " \
                           "on each use. Revocation list stored in SQL Server. " \
                           "Guard all protected routes with @UseGuards(JwtAuthGuard).",
    status:                :done,
    priority:              :critical,
    owner:                 admin,
    assignee:              dana,
    dev_estimate_hours:    20.0,
    tester_estimate_hours: 8.0,
    actual_hours:          "2d 2h",
    attach_spec:           false
  },
  {
    project:               projects[2],
    kind:           :bug_fix,
    level:                 :simple,
    how_to_reproduce:      "1. Log in to the application\n2. Navigate to any authenticated page\n3. Press F5 (hard browser refresh)\n4. Observe: user is logged out / Pinia store is cleared\n5. Expected: session should persist across browser refreshes",
    title:                 "Pinia store state lost on browser refresh (missing persist plugin)",
    description:           "After a hard browser refresh all Pinia store state is cleared, " \
                           "forcing the user to re-authenticate. Fix: install " \
                           "pinia-plugin-persistedstate and configure localStorage persistence " \
                           "for the auth and session stores.",
    status:                :open,
    priority:              :medium,
    owner:                 qa_user,
    assignee:              oren,
    dev_estimate_hours:    4.0,
    tester_estimate_hours: 2.0,
    actual_hours:          "3h",
    attach_spec:           false
  },
  {
    project:               projects[2],
    kind:           :bug_fix,
    level:                 :complex,
    how_to_reproduce:      "1. Run load test with 200 concurrent virtual users (k6 or Artillery)\n2. Monitor SQL Server connection count via sys.dm_exec_connections\n3. Observe: requests fail with ConnectionTimeoutError after ~60 seconds\n4. Expected: connection pool handles 200+ concurrent users without exhaustion",
    title:                 "SQL Server connection pool exhaustion under concurrent load",
    description:           "Under load testing (200 concurrent users) the SQL Server connection " \
                           "pool is exhausted after ~60 seconds. TypeORM default pool max is 10. " \
                           "Increase pool size to 50 and enable connection timeout monitoring. " \
                           "Also audit for missing .release() calls in raw query paths.",
    status:                :in_review,
    priority:              :critical,
    owner:                 team_lead,
    assignee:              avi,
    dev_estimate_hours:    8.0,
    tester_estimate_hours: 4.0,
    actual_hours:          "11h",
    pr_number:             18,
    pr_url:                "https://github.com/assaf416/digital-internet-services/pulls/18",
    attach_spec:           false
  },

  # ── Work Management System ────────────────────────────────────────
  {
    project:               projects[3],
    kind:           :story,
    level:                 :complex,
    title:                 "Kanban board with drag-and-drop using Next.js 16 Server Actions",
    description:           "Implement a drag-and-drop Kanban board for sprint tickets using " \
                           "@dnd-kit/core. Board columns: Backlog, In Progress, In Review, Done. " \
                           "Column transitions should call Next.js 16 Server Actions to persist " \
                           "status changes. Optimistic UI updates required.",
    status:                :in_progress,
    priority:              :high,
    owner:                 pm_user,
    assignee:              noam,
    dev_estimate_hours:    32.0,
    tester_estimate_hours: 12.0,
    actual_hours:          "4d",
    attach_spec:           true
  },
  {
    project:               projects[3],
    kind:           :story,
    level:                 :moderate,
    title:                 "PostgreSQL full-text search for tickets and projects",
    description:           "Add a tsvector column to the tickets table populated from title + " \
                           "description. Create a GIN index. Expose a /search endpoint backed by " \
                           "to_tsquery. Frontend: debounced search input with highlighted " \
                           "matches using ts_headline.",
    status:                :backlog,
    priority:              :medium,
    owner:                 admin,
    assignee:              nil,
    dev_estimate_hours:    16.0,
    tester_estimate_hours: 4.0,
    attach_spec:           true
  },
  {
    project:               projects[3],
    kind:           :story,
    level:                 :moderate,
    title:                 "Jenkins CI pipeline integration with Bun test runner",
    description:           "Configure Jenkinsfile to run bun test --reporter=junit, parse " \
                           "the JUnit XML output, and publish test results in Jenkins. " \
                           "Pipeline stages: Install → Lint → Test → Build → Deploy to staging. " \
                           "Cache bun.lock in Jenkins workspace for faster installs.",
    status:                :done,
    priority:              :medium,
    owner:                 pm_user,
    assignee:              dana,
    dev_estimate_hours:    20.0,
    tester_estimate_hours: 8.0,
    actual_hours:          "2d 6h",
    attach_spec:           false
  },
  {
    project:               projects[3],
    kind:           :bug_fix,
    level:                 :moderate,
    how_to_reproduce:      "1. Open the project in VSCode on Windows (WSL2)\n2. Start the dev server: bun run dev\n3. Rename any .ts source file in VSCode (F2 or right-click → Rename)\n4. Observe: Bun dev server crashes with ENOENT error\n5. Workaround: set BUN_HMR_POLL=1 bun run dev",
    title:                 "Bun hot-reload crashes on Windows WSL2 after file rename",
    description:           "When a source file is renamed in VSCode on Windows (which triggers " \
                           "a delete + create inotify event pair), Bun's HMR watcher crashes " \
                           "with ENOENT. Workaround: enable polling via BUN_HMR_POLL=1. " \
                           "Proper fix: debounce inotify events in the watcher.",
    status:                :open,
    priority:              :high,
    owner:                 qa_user,
    assignee:              oren,
    dev_estimate_hours:    6.0,
    tester_estimate_hours: 2.0,
    actual_hours:          "6.5h",
    attach_spec:           false
  },
  {
    project:               projects[3],
    kind:           :bug_fix,
    level:                 :complex,
    how_to_reproduce:      "1. Open the sprint detail page for a sprint with >1000 tickets\n2. Apply a status filter (e.g. in_progress)\n3. Run EXPLAIN ANALYZE on the generated SQL in psql\n4. Observe: Seq Scan on tickets instead of Index Scan\n5. Expected: GIN index on (sprint_id, status) should be used",
    title:                 "PostgreSQL query planner ignores GIN index on sprint filter",
    description:           "The sprint ticket list query performs a sequential scan on tickets " \
                           "even though a GIN index on (sprint_id, status) exists. Cause: the " \
                           "ORM is casting sprint_id to text in the WHERE clause. Fix by " \
                           "ensuring the parameter type matches the column type (bigint).",
    status:                :in_review,
    priority:              :high,
    owner:                 team_lead,
    assignee:              avi,
    dev_estimate_hours:    8.0,
    tester_estimate_hours: 4.0,
    actual_hours:          "10h",
    pr_number:             9,
    pr_url:                "https://github.com/assaf416/work-management-system/pulls/9",
    attach_spec:           false
  },
  {
    project:               projects[3],
    kind:           :spike,
    level:                 :moderate,
    title:                 "Evaluate Bun native SQLite vs PostgreSQL for local dev workflow",
    description:           "Investigate using Bun's built-in SQLite for local development " \
                           "(faster setup, zero deps) vs keeping PostgreSQL everywhere. " \
                           "Produce a short decision document covering: performance on test " \
                           "suite, migration tooling compatibility, and Docker impact.",
    status:                :backlog,
    priority:              :low,
    owner:                 admin,
    assignee:              nil,
    dev_estimate_hours:    16.0,
    tester_estimate_hours: 0.0,
    attach_spec:           true
  },

  # ── DevTeam Hub (this app) ────────────────────────────────────────
  {
    project:               projects[4],
    kind:           :story,
    level:                 :moderate,
    title:                 "Project membership management with role-based email notifications",
    description:           "Admins and project leads can add/remove users from projects via the " \
                           "project show page. Adding a member sends a ProjectMailer email and " \
                           "creates an Activity record (event_type: member_added). Roles: " \
                           "developer, viewer, lead, qa.",
    status:                :done,
    priority:              :high,
    owner:                 admin,
    assignee:              admin,
    dev_estimate_hours:    24.0,
    tester_estimate_hours: 8.0,
    actual_hours:          "3d 2h",
    attach_spec:           false
  },
  {
    project:               projects[4],
    kind:           :story,
    level:                 :moderate,
    title:                 "Activity feed with APM exception ingestion via webhook",
    description:           "Timeline activity feed on each project page showing member changes, " \
                           "CI results, deployments, and exceptions. APM exceptions ingested via " \
                           "POST /webhooks/exception (verified with X-APM-Key header). " \
                           "Activity model has 10 event types with icons and metadata.",
    status:                :done,
    priority:              :high,
    owner:                 admin,
    assignee:              team_lead,
    dev_estimate_hours:    16.0,
    tester_estimate_hours: 4.0,
    actual_hours:          "1d 6h",
    attach_spec:           false
  },
  {
    project:               projects[4],
    kind:           :story,
    level:                 :complex,
    title:                 "Slack-style 3-column layout with Hotwire real-time chat",
    description:           "Redesign the app shell as a 3-column layout (dark sidebar, main " \
                           "content, right notifications panel). Chat rooms with Turbo Frames " \
                           "for real-time message updates. Sidebar shows project CI status, " \
                           "deployments, and PR counts with accordion per project.",
    status:                :done,
    priority:              :high,
    owner:                 admin,
    assignee:              noam,
    dev_estimate_hours:    40.0,
    tester_estimate_hours: 8.0,
    actual_hours:          "5d 2h",
    attach_spec:           false
  },
  {
    project:               projects[4],
    kind:           :story,
    level:                 :moderate,
    title:                 "Auto-create git branch and notify assignee on ticket assignment",
    description:           "When a ticket is assigned to a developer, automatically create a " \
                           "branch on the Gitea repo (feature/T-{id}-{slug} or bugfix/...) " \
                           "and send the assignee an in-app notification with the exact " \
                           "git fetch + git checkout command they need to run.",
    status:                :in_progress,
    priority:              :high,
    owner:                 admin,
    assignee:              dana,
    dev_estimate_hours:    16.0,
    tester_estimate_hours: 4.0,
    actual_hours:          "17h",
    attach_spec:           true
  },
  {
    project:               projects[4],
    kind:           :bug_fix,
    level:                 :simple,
    how_to_reproduce:      "1. Open any project page with the sidebar visible\n2. Expand a project accordion section in the sidebar\n3. Click any Turbo navigation link (tab, ticket, etc.)\n4. Observe: sidebar accordion collapses back to default state\n5. Expected: accordion open/close state should persist across Turbo navigation",
    title:                 "Sidebar accordion state lost on Turbo navigation",
    description:           "When navigating between pages via Turbo Drive, the sidebar project " \
                           "accordion forgets which sections were open. The Stimulus controller " \
                           "needs to persist accordion state in sessionStorage and restore it " \
                           "on connect().",
    status:                :open,
    priority:              :medium,
    owner:                 qa_user,
    assignee:              oren,
    dev_estimate_hours:    2.0,
    tester_estimate_hours: 1.0,
    actual_hours:          "2.5h",
    attach_spec:           false
  },
  {
    project:               projects[4],
    kind:           :spike,
    level:                 :moderate,
    title:                 "Evaluate ActionCable for real-time chat vs Turbo Streams polling",
    description:           "Investigate whether replacing the current Turbo Frames + form-submit " \
                           "chat with ActionCable WebSocket broadcasts would improve UX without " \
                           "adding operational complexity (Redis pub/sub, cable config). " \
                           "Document latency, resource usage, and deployment implications.",
    status:                :backlog,
    priority:              :low,
    owner:                 admin,
    assignee:              nil,
    dev_estimate_hours:    16.0,
    tester_estimate_hours: 0.0,
    attach_spec:           true
  }
]

# Disable auto-branch-callback during seed to avoid noise
# (callback will still fire for the assigned ones — that's intentional)
created_ticket_count = 0
tickets_data.each do |t|
  ticket = Ticket.find_or_create_by!(project: t[:project], title: t[:title]) do |tk|
    tk.kind                  = t[:kind]
    tk.level                 = t[:level]        || :moderate
    tk.description           = t[:description]
    tk.status                = t[:status]
    tk.priority              = t[:priority]
    tk.owner                 = t[:owner]
    tk.assignee              = t[:assignee]
    tk.dev_estimate_hours    = t[:dev_estimate_hours]
    tk.tester_estimate_hours = t[:tester_estimate_hours]
    tk.actual_hours          = t[:actual_hours]
    tk.how_to_reproduce      = t[:how_to_reproduce] if t[:how_to_reproduce]
    tk.pr_number             = t[:pr_number] if t[:pr_number]
    tk.pr_url                = t[:pr_url]    if t[:pr_url]
    created_ticket_count    += 1
  end

  # Always keep new fields up to date (idempotent on re-seed)
  ticket.update_columns(
    kind:  Ticket.kinds[t[:kind].to_s],
    level: Ticket.levels[(t[:level] || :moderate).to_s],
    actual_hours: t[:actual_hours]
  )
  ticket.update_column(:how_to_reproduce, t[:how_to_reproduce]) if t[:how_to_reproduce].present?

  # Attach a spec/design document to feature and spike tickets (idempotent)
  next unless t[:attach_spec] && ticket.attachments.none?

  kind_label = t[:kind].to_s.capitalize
  spec_content = <<~MARKDOWN
    # #{kind_label.to_s.humanize} Specification: #{ticket.title}

    **Project:** #{ticket.project.name}
    **Kind:** #{kind_label.to_s.humanize.gsub("_", " ")}
    **Priority:** #{ticket.priority.capitalize}
    **Dev estimate:** #{t[:dev_estimate_hours]}h
    **QA estimate:** #{t[:tester_estimate_hours]}h

    ## Overview

    #{ticket.description}

    ## Acceptance Criteria

    - [ ] Implementation matches the described behaviour
    - [ ] Unit tests cover the main code paths
    - [ ] QA sign-off on the acceptance criteria
    - [ ] Documentation updated if applicable

    ## Technical Notes

    _To be filled in by the assigned developer._
  MARKDOWN

  ticket.attachments.attach(
    io:           StringIO.new(spec_content),
    filename:     "spec-T#{ticket.id}.md",
    content_type: "text/markdown"
  )
end

puts "  ✓ #{tickets_data.size} tickets (#{created_ticket_count} newly created)"
puts "  ✓ spec docs attached to feature/spike tickets"

# ─────────────────────────────────────────────────────────────────
# Milestones
# ─────────────────────────────────────────────────────────────────
milestones_data = [
  # Print Server / TDI
  { project: projects[0], name: "v3.2 — PDF Export & Profiles",   description: "PDF print queue export and per-printer duplex profiles.", due_date: Date.new(2026, 4, 30), status: :completed   },
  { project: projects[0], name: "v3.3 — Performance Hardening",   description: "Fix network timeout bugs and paper-size locale issues.",   due_date: Date.new(2026, 5, 30), status: :in_progress },
  { project: projects[0], name: "v4.0 — .NET 4.8.1 Upgrade",      description: "Full framework upgrade and regression suite.",              due_date: Date.new(2026, 6, 30), status: :open        },

  # TDI2
  { project: projects[1], name: "v1.0 — MVP Launch",              description: "Core order processing with RabbitMQ and EF Core.",         due_date: Date.new(2026, 4, 15), status: :completed   },
  { project: projects[1], name: "v1.1 — Resilience & Logging",    description: "Dead-letter exchange, structured Serilog logging.",         due_date: Date.new(2026, 5, 20), status: :in_progress },
  { project: projects[1], name: "v2.0 — EF Core Migration",       description: "Full data-layer migration to EF Core 9 code-first.",        due_date: Date.new(2026, 7, 1),  status: :open        },

  # Digital Internet Services
  { project: projects[2], name: "v2.0 — Vue 3 Dashboard",         description: "Statistics dashboard and JWT auth overhaul.",              due_date: Date.new(2026, 4, 20), status: :completed   },
  { project: projects[2], name: "v2.1 — Stability & Performance",  description: "Fix Pinia persistence and connection pool issues.",         due_date: Date.new(2026, 5, 25), status: :in_progress },
  { project: projects[2], name: "v3.0 — Docker CI/CD",            description: "Containerised Windows deployment pipeline.",                due_date: Date.new(2026, 6, 15), status: :open        },

  # Work Management System
  { project: projects[3], name: "v1.0 — Kanban & Search",         description: "Drag-and-drop Kanban and PostgreSQL full-text search.",    due_date: Date.new(2026, 4, 25), status: :completed   },
  { project: projects[3], name: "v1.1 — CI & Bug Fixes",          description: "Jenkins Bun pipeline, fix hot-reload and query planner.",   due_date: Date.new(2026, 5, 28), status: :in_progress },
  { project: projects[3], name: "v2.0 — Bun Native Evaluation",   description: "Evaluate Bun SQLite and optimise dev workflow.",            due_date: Date.new(2026, 7, 15), status: :open        },

  # DevTeam Hub
  { project: projects[4], name: "v1.0 — Core Platform",           description: "Projects, tickets, CI dashboard, chat, notifications.",    due_date: Date.new(2026, 4, 10), status: :completed   },
  { project: projects[4], name: "v1.1 — Sprints & Docs",          description: "Sprint CRUD, WYSIWYG docs, customer sidebar.",             due_date: Date.new(2026, 5, 31), status: :in_progress },
  { project: projects[4], name: "v2.0 — Video Huddles",           description: "Jitsi huddles, team presence, meeting recordings.",        due_date: Date.new(2026, 6, 30), status: :open        }
]

milestones = milestones_data.map do |m|
  Milestone.find_or_create_by!(project: m[:project], name: m[:name]) do |ms|
    ms.description = m[:description]
    ms.due_date    = m[:due_date]
    ms.status      = m[:status]
  end
end
puts "  ✓ #{milestones.size} milestones"

today  = Date.today

# ─────────────────────────────────────────────────────────────────
# Deployments
# ─────────────────────────────────────────────────────────────────
deployments_data = [
  # Print Server / TDI
  { project: projects[0], version: "3.1.4", environment: "production", deploy_type: :windows_installer, status: :succeeded,   deployed_at: today - 42, deployed_by: noam,  notes: "Stable release. No issues reported."               },
  { project: projects[0], version: "3.2.0", environment: "staging",    deploy_type: :windows_installer, status: :succeeded,   deployed_at: today - 20, deployed_by: dana,  notes: "PDF export feature deployed to staging."            },
  { project: projects[0], version: "3.2.0", environment: "production", deploy_type: :windows_installer, status: :succeeded,   deployed_at: today -  7, deployed_by: team_lead, notes: "Signed off by QA. Released after successful UAT."  },
  { project: projects[0], version: "3.3.0-beta", environment: "staging", deploy_type: :windows_installer, status: :in_progress, deployed_at: today -  1, deployed_by: dana, notes: "Bug-fix sprint build. Under QA review."             },

  # TDI2
  { project: projects[1], version: "1.0.0", environment: "staging",    deploy_type: :windows_service,   status: :succeeded,   deployed_at: today - 35, deployed_by: noam,  notes: "First staging deploy of the new platform."         },
  { project: projects[1], version: "1.0.0", environment: "production", deploy_type: :windows_service,   status: :succeeded,   deployed_at: today - 28, deployed_by: team_lead, notes: "MVP go-live. All smoke tests passed."             },
  { project: projects[1], version: "1.1.0", environment: "staging",    deploy_type: :windows_service,   status: :succeeded,   deployed_at: today - 10, deployed_by: avi,   notes: "Dead-letter exchange + Serilog upgrade."            },
  { project: projects[1], version: "1.1.0", environment: "production", deploy_type: :windows_service,   status: :pending,     deployed_at: nil,        deployed_by: team_lead, notes: "Scheduled after race-condition fix merges."      },

  # Digital Internet Services
  { project: projects[2], version: "2.0.1", environment: "staging",    deploy_type: :docker,            status: :succeeded,   deployed_at: today - 30, deployed_by: dana,  notes: "Vue 3 dashboard + JWT auth."                       },
  { project: projects[2], version: "2.0.1", environment: "production", deploy_type: :docker,            status: :succeeded,   deployed_at: today - 21, deployed_by: team_lead, notes: "Customer-facing release approved."               },
  { project: projects[2], version: "2.1.0", environment: "staging",    deploy_type: :docker,            status: :failed,      deployed_at: today -  5, deployed_by: oren,  notes: "Deploy failed — connection pool config error. Reverted." },
  { project: projects[2], version: "2.1.1", environment: "staging",    deploy_type: :docker,            status: :succeeded,   deployed_at: today -  2, deployed_by: oren,  notes: "Hotfix: correct pool size env vars in Docker compose."   },

  # Work Management System
  { project: projects[3], version: "1.0.0", environment: "staging",    deploy_type: :web_app,           status: :succeeded,   deployed_at: today - 28, deployed_by: noam,  notes: "Kanban board and search features complete."        },
  { project: projects[3], version: "1.0.0", environment: "production", deploy_type: :web_app,           status: :succeeded,   deployed_at: today - 18, deployed_by: pm_user, notes: "Production launch. Stakeholder sign-off received."  },
  { project: projects[3], version: "1.1.0", environment: "staging",    deploy_type: :web_app,           status: :in_progress, deployed_at: today -  1, deployed_by: dana,  notes: "Jenkins CI pipeline running Bun test suite."       },

  # DevTeam Hub
  { project: projects[4], version: "1.0.0", environment: "production", deploy_type: :web_app,           status: :succeeded,   deployed_at: today - 40, deployed_by: admin, notes: "Initial platform launch."                          },
  { project: projects[4], version: "1.1.0", environment: "staging",    deploy_type: :web_app,           status: :succeeded,   deployed_at: today -  8, deployed_by: admin, notes: "Sprints, WYSIWYG docs, customer portal added."     },
  { project: projects[4], version: "1.1.0", environment: "production", deploy_type: :web_app,           status: :succeeded,   deployed_at: today -  3, deployed_by: admin, notes: "Passed internal QA. Released to team."             },
  { project: projects[4], version: "2.0.0-alpha", environment: "staging", deploy_type: :web_app,        status: :pending,     deployed_at: nil,        deployed_by: admin, notes: "Video huddles milestone — pending final review."   }
]

deployments_data.each do |d|
  Deployment.find_or_create_by!(project: d[:project], version: d[:version], environment: d[:environment]) do |dep|
    dep.deploy_type  = d[:deploy_type]
    dep.status       = d[:status]
    dep.deployed_at  = d[:deployed_at]
    dep.deployed_by  = d[:deployed_by]
    dep.notes        = d[:notes]
  end
end

puts "  ✓ #{deployments_data.size} curated deployments"

# ─────────────────────────────────────────────────────────────────
# Servers + enriched deployments (5 servers, 100 deployments) + heartbeats
# ─────────────────────────────────────────────────────────────────
SERVERS = [
  { ip: "10.0.10.21", name: "prod-web-01", os: "Ubuntu 22.04 LTS" },
  { ip: "10.0.10.22", name: "prod-app-02", os: "Windows Server 2022" },
  { ip: "10.0.20.31", name: "staging-01",  os: "Ubuntu 22.04 LTS" },
  { ip: "10.0.30.41", name: "db-01",       os: "Debian 12" },
  { ip: "10.0.40.51", name: "edge-win-01", os: "Windows Server 2019" }
].freeze

os_snapshot = -> { { "cpu" => rand(10..95), "mem" => rand(20..92), "disk" => rand(30..95),
                     "errors" => (rand < 0.2 ? rand(1..6) : 0) } }
server_for  = ->(srv) { { server_name: srv[:name], server_id: "srv-#{srv[:ip].split('.').last}",
                          server_os: srv[:os], ip_address: srv[:ip] } }

# Backfill server info onto the curated deployments.
Deployment.where(ip_address: nil).find_each do |dep|
  srv = SERVERS.sample
  dep.update!(**server_for.call(srv), os_status: os_snapshot.call,
              log_file_url: "/var/log/devteam/deploy/#{dep.project_id}-#{dep.version}.log")
end

# Grow to 100 total deployments distributed across the 5 servers.
deployers = [ admin, noam, dana, oren, team_lead, avi, pm_user ].compact
versions  = %w[1.0.0 1.1.0 1.2.0 2.0.0 2.1.0 3.0.0 3.1.0 4.0.0]
gen_statuses = %i[succeeded succeeded succeeded failed in_progress pending rolled_back]
while Deployment.count < 100
  project = projects.sample
  srv     = SERVERS.sample
  status  = gen_statuses.sample
  Deployment.create!(
    project:     project,
    version:     "#{versions.sample}-#{rand(100..999)}",
    environment: %w[staging production].sample,
    deploy_type: Deployment.deploy_types.keys.sample,
    status:      status,
    deployed_at: (status == :pending ? nil : today - rand(0..60)),
    deployed_by: deployers.sample,
    notes:       "Automated deployment to #{srv[:name]}.",
    os_status:   os_snapshot.call,
    log_file_url: "/var/log/devteam/deploy/#{project.id}-#{rand(10_000)}.log",
    **server_for.call(srv)
  )
end
puts "  ✓ #{Deployment.count} deployments across #{SERVERS.size} servers"

# Heartbeat time-series — 48 hourly samples per server (CPU/mem/disk/errors).
ServerHeartbeat.delete_all
SERVERS.each do |srv|
  base_cpu = rand(25..55); base_mem = rand(40..70); base_disk = rand(45..78)
  48.times do |i|
    ServerHeartbeat.create!(
      ip_address:   srv[:ip],
      server_name:  srv[:name],
      server_os:    srv[:os],
      cpu:          (base_cpu + rand(-15..30)).clamp(2, 99),
      mem:          (base_mem + rand(-10..25)).clamp(5, 99),
      disk:         (base_disk + (i / 12)).clamp(5, 99),
      error_count:  (rand < 0.1 ? rand(1..4) : 0),
      log_file_url: "/var/log/devteam/#{srv[:name]}.log",
      recorded_at:  (47 - i).hours.ago
    )
  end
end
puts "  ✓ #{ServerHeartbeat.count} server heartbeats"

# ─────────────────────────────────────────────────────────────────
# CI runs + test results (for dashboards/reports)
# ─────────────────────────────────────────────────────────────────
ci_statuses = %i[passed failed passed running cancelled passed error passed]

projects.each_with_index do |project, project_index|
  project_tickets = Ticket.where(project: project).order(:id).to_a

  8.times do |i|
    build_number = "#{project_index + 1}#{format('%03d', i + 1)}"
    status = ci_statuses[i % ci_statuses.size]
    started_at = Time.current - (project_index * 2 + i + 2).days - rand(0..8).hours
    finished_at = %i[passed failed error cancelled].include?(status) ? started_at + rand(4..18).minutes : nil
    ticket = project_tickets[i % project_tickets.size]

    ci_run = CiRun.find_or_create_by!(project: project, build_number: build_number) do |run|
      run.ticket = ticket
      run.triggered_by = [ noam, dana, oren, avi, team_lead ].compact.sample
      run.status = status
      run.branch_name = ticket&.branch_name.presence || "feature/demo-#{project.id}-#{i}"
      run.commit_sha = SecureRandom.hex(20)
      run.started_at = started_at
      run.finished_at = finished_at
      run.log_url = "http://jenkins.local/job/#{project.name.parameterize}/#{build_number}/console"
    end

    suites = [ "unit", "integration", "e2e" ]
    suites.each_with_index do |suite_name, suite_idx|
      total = 30 + rand(15..35)
      failed = status == :failed && suite_idx == 1 ? rand(1..4) : (status == :error ? rand(2..6) : rand(0..1))
      skipped = rand(0..3)
      passed = [ total - failed - skipped, 0 ].max

      TestResult.find_or_create_by!(ci_run: ci_run, suite_name: "#{project.name} #{suite_name}") do |tr|
        tr.total = total
        tr.passed = passed
        tr.failed = failed
        tr.skipped = skipped
        tr.duration_ms = rand(5000..160000)
        tr.xml_report = "<testsuite name='#{suite_name}' tests='#{total}' failures='#{failed}' skipped='#{skipped}'/>"
      end
    end
  end
end

puts "  ✓ CI runs and test results seeded for reports"

# ─────────────────────────────────────────────────────────────────
# Meetings  (standups, planning, reviews, retros, demos)
# ─────────────────────────────────────────────────────────────────
meetings_data = [
  # ── Print Server / TDI ────────────────────────────────────────────
  { project: projects[0], sprint_idx: 3, title: "TDI Daily Standup",                  meeting_type: :daily_standup,   status: :scheduled,  scheduled_at: today + 1,  duration: 15,  organizer: team_lead, attendees: [ team_lead, noam, dana, qa_user ],
    agenda: "1. What did you do yesterday?\n2. What will you do today?\n3. Any blockers?",
    jitsi_room: "devteam-tdi-standup" },
  { project: projects[0], sprint_idx: 3, title: "TDI Sprint 4 Planning",              meeting_type: :sprint_planning, status: :completed,  scheduled_at: today - 7,  duration: 90,  organizer: team_lead, attendees: [ team_lead, noam, dana, qa_user, pm_user ],
    agenda: "Review sprint goal, estimate backlog items, assign stories.",
    notes: "Committed to 7 stories. Network timeout bug prioritised as critical.",
    jitsi_room: "devteam-tdi-planning4" },
  { project: projects[0], sprint_idx: 2, title: "TDI Sprint 3 Retrospective",         meeting_type: :retrospective,   status: :completed,  scheduled_at: today - 10, duration: 60,  organizer: team_lead, attendees: [ team_lead, noam, dana, qa_user ],
    agenda: "What went well? What could improve? Action items.",
    notes: "Team velocity exceeded target. CI build times still too slow — add parallel test jobs.",
    jitsi_room: "devteam-tdi-retro3" },
  { project: projects[0], sprint_idx: 3, title: "TDI Customer Demo — Acme Corp",      meeting_type: :demo,            status: :scheduled,  scheduled_at: today + 3,  duration: 45,  organizer: pm_user,   attendees: [ pm_user, team_lead, noam ],
    agenda: "Demonstrate PDF export feature and duplex profile configuration to Acme Corp.",
    jitsi_room: "devteam-tdi-demo-acme" },

  # ── TDI2 ──────────────────────────────────────────────────────────
  { project: projects[1], sprint_idx: 3, title: "TDI2 Daily Standup",                 meeting_type: :daily_standup,   status: :in_progress, scheduled_at: today,      duration: 15, organizer: team_lead, attendees: [ team_lead, noam, dana, oren, avi, qa_user ],
    agenda: "Round-robin: yesterday / today / blockers",
    jitsi_room: "devteam-tdi2-standup" },
  { project: projects[1], sprint_idx: 3, title: "TDI2 Architecture Review",           meeting_type: :other,           status: :completed,   scheduled_at: today - 5,  duration: 60, organizer: admin,     attendees: [ admin, team_lead, noam, avi ],
    agenda: "Review dead-letter exchange design and distributed lock implementation plan.",
    notes: "Agreed on SQL Server sp_getapplock for distributed locks. DLX config reviewed.",
    jitsi_room: "devteam-tdi2-arch" },
  { project: projects[1], sprint_idx: 3, title: "TDI2 Sprint 4 Planning",             meeting_type: :sprint_planning, status: :completed,   scheduled_at: today - 7,  duration: 90, organizer: team_lead, attendees: [ team_lead, noam, dana, oren, avi, qa_user, pm_user ],
    agenda: "Sprint 4 goal alignment. Pull from backlog. Estimate race-condition fix.",
    notes: "Velocity target: 42pts. Race condition fix: 16pts (2 devs). EF Core spike moved to Sprint 5.",
    jitsi_room: "devteam-tdi2-planning4" },
  { project: projects[1], sprint_idx: 2, title: "TDI2 Sprint 3 Review",               meeting_type: :sprint_review,   status: :completed,   scheduled_at: today - 9,  duration: 45, organizer: pm_user,   attendees: [ pm_user, team_lead, noam, dana ],
    agenda: "Demo completed stories. Review against sprint goal.",
    notes: "Serilog logging: done. RabbitMQ DLX: 80% done — carry over to Sprint 4.",
    jitsi_room: "devteam-tdi2-review3" },

  # ── Digital Internet Services ──────────────────────────────────────
  { project: projects[2], sprint_idx: 3, title: "DIS Daily Standup",                  meeting_type: :daily_standup,   status: :scheduled,  scheduled_at: today + 1,  duration: 15, organizer: team_lead, attendees: [ team_lead, noam, dana, oren, avi, qa_user ],
    agenda: "Daily sync — blockers and progress.",
    jitsi_room: "devteam-dis-standup" },
  { project: projects[2], sprint_idx: 3, title: "DIS Connection Pool Post-Mortem",    meeting_type: :other,           status: :completed,  scheduled_at: today - 4,  duration: 60, organizer: qa_user,   attendees: [ qa_user, team_lead, aven = avi ],
    agenda: "Root cause analysis of staging deployment failure. Corrective actions.",
    notes: "Root cause: DOCKER_POOL_MAX env var not injected in compose override. Fix applied in 2.1.1.",
    jitsi_room: "devteam-dis-postmortem" },
  { project: projects[2], sprint_idx: 3, title: "DIS Sprint 4 Planning",              meeting_type: :sprint_planning, status: :completed,  scheduled_at: today - 7,  duration: 90, organizer: team_lead, attendees: [ team_lead, noam, dana, oren, avi, pm_user ],
    agenda: "Plan sprint items: Docker CI/CD pipeline, Pinia persistence fix.",
    notes: "Docker pipeline: 24pts (avi + noam). Pinia fix: 4pts (oren).",
    jitsi_room: "devteam-dis-planning4" },
  { project: projects[2], sprint_idx: 4, title: "DIS Roadmap Review with Globex",     meeting_type: :demo,            status: :scheduled,  scheduled_at: today + 5,  duration: 60, organizer: pm_user,   attendees: [ pm_user, team_lead, dana ],
    agenda: "Present v2.1 stability improvements and v3.0 Docker pipeline roadmap to Globex Solutions.",
    jitsi_room: "devteam-dis-globex-roadmap" },

  # ── Work Management System ─────────────────────────────────────────
  { project: projects[3], sprint_idx: 3, title: "WMS Daily Standup",                  meeting_type: :daily_standup,   status: :scheduled,  scheduled_at: today + 1,  duration: 15, organizer: pm_user,   attendees: [ pm_user, noam, dana, oren, avi ],
    agenda: "Daily sync.",
    jitsi_room: "devteam-wms-standup" },
  { project: projects[3], sprint_idx: 3, title: "WMS Sprint 4 Planning",              meeting_type: :sprint_planning, status: :completed,  scheduled_at: today - 7,  duration: 90, organizer: pm_user,   attendees: [ pm_user, noam, dana, oren, avi, qa_user ],
    agenda: "Plan: Jenkins CI pipeline, WSL2 hot-reload fix, PostgreSQL index bug.",
    notes: "Bun test runner integration: 20pts. Hot-reload bug: 6pts (oren).",
    jitsi_room: "devteam-wms-planning4" },
  { project: projects[3], sprint_idx: 2, title: "WMS Sprint 3 Retrospective",         meeting_type: :retrospective,   status: :completed,  scheduled_at: today - 10, duration: 60, organizer: pm_user,   attendees: [ pm_user, noam, dana, oren, avi, qa_user ],
    agenda: "Retro: went well / improve / action items.",
    notes: "Kanban DnD well-received. Need better cross-browser testing for drag events. Add playwright tests.",
    jitsi_room: "devteam-wms-retro3" },
  { project: projects[3], sprint_idx: 3, title: "WMS One-on-One: PM & Noam",          meeting_type: :one_on_one,      status: :scheduled,  scheduled_at: today + 2,  duration: 30, organizer: pm_user,   attendees: [ pm_user, noam ],
    agenda: "Career check-in. Discuss Kanban implementation progress and next sprint scope.",
    jitsi_room: "devteam-wms-1on1-noam" },

  # ── DevTeam Hub ────────────────────────────────────────────────────
  { project: projects[4], sprint_idx: 3, title: "DevTeam Daily Standup",              meeting_type: :daily_standup,   status: :in_progress, scheduled_at: today,      duration: 15, organizer: admin,     attendees: [ admin, team_lead, noam, dana, qa_user ],
    agenda: "1. Yesterday 2. Today 3. Blockers",
    jitsi_room: "devteam-hub-standup" },
  { project: projects[4], sprint_idx: 3, title: "DevTeam Hub Sprint 4 Planning",      meeting_type: :sprint_planning, status: :completed,   scheduled_at: today - 7,  duration: 90, organizer: admin,     attendees: [ admin, team_lead, noam, dana, qa_user, pm_user ],
    agenda: "Review sprint goal: video huddles milestone. Estimate Jitsi integration stories.",
    notes: "Sprint 4 goal: ship Jitsi huddles + team presence sidebar. 9 stories totalling 42pts.",
    jitsi_room: "devteam-hub-planning4" },
  { project: projects[4], sprint_idx: 2, title: "DevTeam Hub Sprint 3 Review",        meeting_type: :sprint_review,   status: :completed,   scheduled_at: today - 9,  duration: 60, organizer: admin,     attendees: [ admin, team_lead, noam, dana, qa_user ],
    agenda: "Demo sprint deliverables: sprint views, WYSIWYG editor, customers sidebar.",
    notes: "All stories shipped. WYSIWYG editor praised. Sprint CRUD views look polished.",
    jitsi_room: "devteam-hub-review3" },
  { project: projects[4], sprint_idx: 4, title: "All-Hands Team Meeting",             meeting_type: :other,           status: :scheduled,   scheduled_at: today + 7,  duration: 60, organizer: admin,     attendees: users,
    agenda: "Company updates, project status round-table, Q&A.",
    jitsi_room: "devteam-allhands-may2026" }
]

meetings_data.each do |m|
  meeting = Meeting.find_or_create_by!(project: m[:project], title: m[:title]) do |mt|
    mt.meeting_type     = m[:meeting_type]
    mt.status           = m[:status]
    mt.scheduled_at     = m[:scheduled_at].is_a?(Date) ? m[:scheduled_at].to_time + 9.hours : m[:scheduled_at]
    mt.duration_minutes = m[:duration]
    mt.organizer        = m[:organizer]
    mt.jitsi_room       = m[:jitsi_room]
    mt.agenda           = m[:agenda]
    mt.notes            = m[:notes] if m[:notes]
  end
  # Add attendees idempotently
  (m[:attendees] || []).flatten.compact.uniq.each do |u|
    MeetingAttendee.find_or_create_by!(meeting: meeting, user: u)
  end
end

puts "  ✓ #{meetings_data.size} meetings with attendees"

# ─────────────────────────────────────────────────────────────────
# Demo notifications (debug + exception) for each project
# ─────────────────────────────────────────────────────────────────
demo_recipients = [ admin, team_lead, qa_user, noam, dana, oren, avi, pm_user ].compact.uniq

debug_templates = [
  "Background sync completed in %{duration}ms for %{project}",
  "Webhook payload accepted for %{project}; queue depth=%{queue_depth}",
  "CI status poll updated for %{project}: latest build #%{build_number}",
  "Deploy marker processed for %{project} in %{duration}ms"
]

exception_templates = [
  {
    error: "NoMethodError: undefined method `[]' for nil:NilClass",
    backtrace: "app/services/sync_pull_request_service.rb:41:in `parse_payload'\napp/jobs/sync_pull_request_job.rb:12:in `perform'\nlib/tasks/sync.rake:8:in `block (2 levels) in <main>'"
  },
  {
    error: "ActiveRecord::RecordInvalid: Validation failed: Email can't be blank",
    backtrace: "app/models/customer.rb:19:in `create_from_webhook!'\napp/controllers/webhooks_controller.rb:64:in `exception'\nconfig/routes.rb:127:in `block in <main>'"
  },
  {
    error: "Faraday::TimeoutError: execution expired",
    backtrace: "app/services/gitea_service.rb:27:in `post'\napp/services/ticket_branch_service.rb:29:in `try_create_gitea_branch'\napp/controllers/tickets_controller.rb:88:in `assign'"
  }
]

projects.each_with_index do |project, idx|
  recipient = demo_recipients[idx % demo_recipients.size]

  debug_message = format(
    debug_templates[idx % debug_templates.size],
    duration: rand(45..480),
    project: project.name,
    queue_depth: rand(0..25),
    build_number: rand(1000..9999)
  )

  Notification.where(
    recipient: recipient,
    message: debug_message
  ).first_or_create! do |n|
    n.type = "Notification"
    n.params = {
      "project_id" => project.id,
      "project_name" => project.name,
      "severity" => "debug",
      "url" => "/projects/#{project.id}"
    }
    n.read_at = [ nil, Time.current - rand(1..72).hours ].sample
  end

  exception_info = exception_templates[idx % exception_templates.size]
  exception_message = "Exception in #{project.name} while processing background job"

  Notification.where(
    recipient: recipient,
    message: exception_message
  ).first_or_create! do |n|
    n.type = "Notification"
    n.error_message = exception_info[:error]
    n.backtrace = exception_info[:backtrace]
    n.params = {
      "project_id" => project.id,
      "project_name" => project.name,
      "severity" => "error",
      "url" => "/projects/#{project.id}",
      "message" => exception_message,
      "error_message" => exception_info[:error]
    }
    n.read_at = nil
  end
end

puts "  ✓ Demo notifications created for #{projects.size} projects"

# ─────────────────────────────────────────────────────────────────
# Fake Pull Requests per project
# ─────────────────────────────────────────────────────────────────
pr_statuses = %w[open review merged closed]

projects.each do |project|
  project_tickets = Ticket.where(project: project).order(:id).limit(6)
  next if project_tickets.blank?

  3.times do |i|
    ticket = project_tickets[i % project_tickets.size]
    status = pr_statuses[i % pr_statuses.size]
    pr_number = 1000 + (project.id * 10) + i

    title = case i
    when 0 then "Improve error handling for #{project.name} workflows"
    when 1 then "Add test coverage for #{project.name} critical paths"
    else "Refactor background jobs and logging in #{project.name}"
    end

    PullRequest.where(project: project, pr_number: pr_number).first_or_create! do |pr|
      pr.ticket = ticket
      pr.title = title
      pr.description = "Auto-generated demo PR for #{project.name}. Includes bug fixes, tests, and observability updates."
      pr.status = status
      pr.author = [ noam, dana, oren, avi, team_lead ].compact.sample&.name || "System"
      pr.gitea_url = "http://gitea.local/devteam/#{project.name.parameterize}/pulls/#{pr_number}"
      pr.code_changed = "Updated service layer, controller guards, and serializer mappings."
      pr.test_code = "Added request specs + UI checks and improved edge-case coverage."
      pr.build_errors = (status == "closed" ? "CI flaky test detected on pipeline ##{rand(3000..5000)}" : nil)
      pr.synced_at = Time.current - rand(1..96).hours
      pr.merged_at = status == "merged" ? Time.current - rand(1..72).hours : nil
      pr.files_changed = [
        "app/services/#{project.name.parameterize(separator: '_')}_service.rb",
        "app/controllers/#{project.name.parameterize(separator: '_')}_controller.rb",
        "spec/requests/#{project.name.parameterize(separator: '_')}_api_spec.rb",
        "features/#{project.name.parameterize(separator: '_')}.feature"
      ]
      pr.pr_comments_data = [
        { "author" => "qa-bot", "body" => "Regression checks passed in staging." },
        { "author" => "team-lead", "body" => "Please verify null handling for external payload." }
      ]
      pr.latest_test_results = {
        "total" => 48 + rand(1..30),
        "passed" => 45 + rand(1..25),
        "failed" => rand(0..2),
        "skipped" => rand(0..3)
      }
    end
  end
end

puts "  ✓ Fake pull requests seeded for all projects"

# ──────────────────────────────────────────────────────────────────────────────
# Rich PR data for EVERY ticket: per-file content (for the code viewer/editor)
# and structured test results (for the test list + coverage).
# ──────────────────────────────────────────────────────────────────────────────
def pr_language_for(project)
  ts = project.tech_stack.to_s
  return "csharp"     if ts.match?(/C#|\.NET|VB/i)
  return "javascript" if ts.match?(/Vue|Node|Next|Nest|TypeScript|JavaScript/i)
  "ruby"
end

def pr_feature_content(ticket)
  name = ticket.title.truncate(60)
  <<~GHERKIN
    Feature: #{name}
      As a user
      I want the behaviour described in T-#{ticket.id}
      So that the product works as expected

      Background:
        Given the application is running

      Scenario: Happy path
        Given a valid request
        When the user performs the action
        Then the expected result is returned

      Scenario: Validation error
        Given an invalid request
        When the user performs the action
        Then a helpful error is shown
  GHERKIN
end

def pr_source_content(ticket, lang)
  klass = ticket.title.split.first(3).map(&:capitalize).join.gsub(/\W/, "").presence || "Feature"
  case lang
  when "csharp"
    "public class #{klass}Service\n{\n    public Result Handle(Request request)\n    {\n        if (!request.Valid) return Result.Error(\"invalid\");\n        // T-#{ticket.id}: #{ticket.title.truncate(50)}\n        return Result.Ok(Process(request));\n    }\n}\n"
  when "javascript"
    "export function handle#{klass}(request) {\n  if (!request.valid) throw new Error('invalid');\n  // T-#{ticket.id}: #{ticket.title.truncate(50)}\n  return process(request);\n}\n"
  else
    "class #{klass}Service\n  def initialize(request)\n    @request = request\n  end\n\n  # T-#{ticket.id}: #{ticket.title.truncate(50)}\n  def call\n    raise ArgumentError, 'invalid' unless @request.valid?\n    process(@request)\n  end\nend\n"
  end
end

def pr_test_source(lang)
  case lang
  when "csharp"
    "[Test]\npublic void Handle_ReturnsOk_ForValidRequest()\n{\n    Assert.IsTrue(new Service().Handle(Valid()).Ok);\n}\n"
  when "javascript"
    "test('handles a valid request', () => {\n  expect(handle({ valid: true })).toBeTruthy();\n});\n"
  else
    "RSpec.describe Service do\n  it 'returns ok for a valid request' do\n    expect(described_class.new(valid_request).call).to be_present\n  end\nend\n"
  end
end

def pr_files_and_tests(ticket, lang, repo_base, branch)
  slug = ticket.title.parameterize(separator: "_").first(40).presence || "feature"
  ext, src_dir, test_path = case lang
  when "csharp"     then [ ".cs", "src", "tests/#{slug}_tests.cs" ]
  when "javascript" then [ ".js", "src", "tests/#{slug}.test.js" ]
  else                   [ ".rb", "app/services", "spec/services/#{slug}_spec.rb" ]
  end
  src_path     = "#{src_dir}/#{slug}#{ext}"
  feature_path = "features/#{slug}.feature"

  blob = ->(path) { "#{repo_base}/src/branch/#{branch}/#{path}" }
  files = [
    { "path" => src_path, "url" => blob.call(src_path), "language" => PullRequest.language_for(src_path),
      "status" => "modified", "additions" => rand(10..80), "deletions" => rand(0..30),
      "content" => pr_source_content(ticket, lang) },
    { "path" => test_path, "url" => blob.call(test_path), "language" => PullRequest.language_for(test_path),
      "status" => "added", "additions" => rand(8..40), "deletions" => 0,
      "content" => pr_test_source(lang) },
    { "path" => feature_path, "url" => blob.call(feature_path), "language" => "gherkin",
      "status" => "added", "additions" => rand(12..30), "deletions" => 0,
      "content" => pr_feature_content(ticket) }
  ]

  tests = [
    { "name" => "Happy path",        "file" => feature_path, "suite" => "Cucumber", "status" => "passed",                          "time_ms" => rand(120..900) },
    { "name" => "Validation error",  "file" => feature_path, "suite" => "Cucumber", "status" => (rand < 0.18 ? "failed" : "passed"), "time_ms" => rand(120..900) },
    { "name" => "returns ok for a valid request", "file" => test_path, "suite" => "Unit", "status" => "passed",                    "time_ms" => rand(20..200) },
    { "name" => "raises on invalid input",        "file" => test_path, "suite" => "Unit", "status" => (rand < 0.1 ? "skipped" : "passed"), "time_ms" => rand(20..200) }
  ]
  [ files, tests ]
end

pr_built = 0
Ticket.includes(:project, :pull_requests).find_each do |ticket|
  pr = ticket.pull_requests.first
  next if pr&.files_data.present?

  project   = ticket.project
  lang      = pr_language_for(project)
  repo_base = (project.repo_url.presence || "http://gitea.local/devteam/#{project.name.parameterize}")
  branch    = ticket.branch_name.presence || project.default_branch.presence || "main"
  files, tests = pr_files_and_tests(ticket, lang, repo_base, branch)
  pr_number = pr&.pr_number || (5000 + ticket.id)

  pr ||= ticket.pull_requests.build(project: project, pr_number: pr_number,
                                    title: "T-#{ticket.id}: #{ticket.title.truncate(60)}")
  pr.assign_attributes(
    project:      project,
    files_data:   files,
    tests_data:   tests,
    files_changed: files.map { |f| f["path"] },
    coverage_percent: rand(68.0..98.0).round(1),
    gitea_url:    pr.gitea_url.presence || "#{repo_base}/pulls/#{pr_number}",
    status:       pr.status.presence || %w[open review merged].sample,
    author:       pr.author.presence || (Project.first && project.members.to_a.sample&.name) || "dev",
    latest_test_results: {
      "total"   => tests.size,
      "passed"  => tests.count { |t| t["status"] == "passed" },
      "failed"  => tests.count { |t| t["status"] == "failed" },
      "skipped" => tests.count { |t| t["status"] == "skipped" }
    },
    synced_at: Time.current - rand(1..72).hours
  )
  pr.save!
  pr_built += 1
end
puts "  ✓ Rich PR data (files + tests) on #{pr_built} tickets; #{PullRequest.count} PRs total"

# ─────────────────────────────────────────────────────────────────
# Documents from docs/ folder
# ─────────────────────────────────────────────────────────────────
docs_to_seed = [
  {
    file:            "docs/cli_manual.html",
    title:           "dt CLI Manual",
    doc_type:        :runbook,
    summary:         "Complete reference for the dt command-line client — setup, ticket management, CI, deployments, and logs.",
    version_number:  "1.0"
  },
  {
    file:            "docs/writing_specs_and_tickets.html",
    title:           "Writing Specs & Tickets — Agile Best Practices",
    doc_type:        :spec,
    summary:         "Guide to writing clear, actionable tickets — user stories, acceptance criteria, ticket kinds, and anti-patterns.",
    version_number:  "1.0"
  },
  {
    file:            "docs/ticket_estimation_guide.html",
    title:           "Ticket Estimation Guide",
    doc_type:        :spec,
    summary:         "Practical guide to story points, complexity levels, hour estimates, planning poker, and tracking velocity.",
    version_number:  "1.0"
  },
  {
    file:            "docs/api_reference.html",
    title:           "API Reference",
    doc_type:        :architecture,
    summary:         "REST API documentation for DevTeam Hub — authentication, endpoints, request/response formats.",
    version_number:  "1.0"
  },
  {
    file:            "docs/infrastructure_guide.html",
    title:           "Infrastructure Guide",
    doc_type:        :architecture,
    summary:         "Deployment architecture, Docker setup, CI/CD pipelines, and production operations guide.",
    version_number:  "1.0"
  },
  {
    file:            "docs/presentation.html",
    title:           "DevTeam Hub Presentation",
    doc_type:        :other,
    summary:         "Overview presentation of the DevTeam Hub platform and capabilities.",
    version_number:  "1.0"
  },
  {
    file:            "docs/automatic_testing_presentation.html",
    title:           "Automatic Testing Presentation",
    doc_type:        :test_coverage,
    summary:         "Presentation on automated testing strategies, frameworks, and best practices.",
    version_number:  "1.0"
  },
  {
    file:            "docs/project_overview.md",
    title:           "Project Overview",
    doc_type:        :spec,
    summary:         "High-level overview of the DevTeam Hub project — goals, architecture, and roadmap.",
    version_number:  "1.0"
  },
  {
    file:            "docs/project_risks.md",
    title:           "Project Risks",
    doc_type:        :risk_management,
    summary:         "Risk register for the DevTeam Hub project — identified risks, mitigations, and contingency plans.",
    version_number:  "1.0"
  },
  {
    file:            "docs/stories_backlog.md",
    title:           "Stories Backlog",
    doc_type:        :user_story,
    summary:         "Product backlog of user stories and feature requests for DevTeam Hub.",
    version_number:  "1.0"
  },
  {
    file:            "docs/code_review_tools_recommendation.html",
    title:           "Code Review & Approval Tools — Recommendation",
    doc_type:        :architecture,
    summary:         "Evaluation of code review tools for CI — SonarQube CE + Ollama AI recommendation with implementation guide.",
    version_number:  "1.0"
  },
  {
    file:            "docs/unified_logging_recommendation.html",
    title:           "Unified Logging — Recommendation & Implementation",
    doc_type:        :architecture,
    summary:         "Unified log management with Grafana Loki + Promtail — format, tools, API, CLI, and CI integration.",
    version_number:  "1.0"
  },
  {
    file:            "docs/local_llm_onprem_guide.html",
    title:           "AI in On-Premises Projects — Local LLM & Hardware Guide",
    doc_type:        :architecture,
    summary:         "Free local-LLM scan + Mac mini M5 hardware recommendation for on-prem dev AI (code review, fixes, docs, presentations).",
    version_number:  "1.0"
  },
  {
    file:            "docs/whats_new_2026.html",
    title:           "What's New (2026) — Feature Brochure",
    doc_type:        :other,
    summary:         "Brochure for the 2026 release: project-scoped AI chat (ask who delivers fastest / estimates best / sprint status), server monitoring, staged tickets, sprints, and ceremonies.",
    version_number:  "1.0"
  },
  {
    file:            "docs/product_overview_en.html",
    title:           "Product Overview (English)",
    doc_type:        :other,
    summary:         "Product document: the need for agile, ticket management & automatic testing; spec→production lifecycle on a local AI engine; iterations, automated ceremonies and Jitsi for remote teams.",
    version_number:  "1.0"
  },
  {
    file:            "docs/product_overview_he.html",
    title:           "סקירת מוצר (עברית)",
    doc_type:        :other,
    summary:         "מסמך מוצר: הצורך באג'ייל, ניהול כרטיסים ובדיקות אוטומטיות; מחזור החיים ממפרט לייצור על מנוע AI מקומי; איטרציות, פגישות אוטומטיות ו-Jitsi לצוותים מרוחקים.",
    version_number:  "1.0"
  }
]

devteam_project = projects[4]
doc_count = 0

docs_to_seed.each do |d|
  filepath = Rails.root.join(d[:file])
  next unless File.exist?(filepath)

  doc = Document.find_or_create_by!(title: d[:title], project: devteam_project) do |doc|
    doc.content        = File.read(filepath)
    doc.doc_type       = d[:doc_type]
    doc.summary        = d[:summary]
    doc.version_number = d[:version_number]
    doc.author         = admin
    doc.is_template    = false
  end
  doc_count += 1
end

puts "  ✓ #{doc_count} documents seeded from docs/ folder"

# ──────────────────────────────────────────────────────────────────────────────
# Tasks  (break every ticket into estimable tasks; some done, some not)
# ──────────────────────────────────────────────────────────────────────────────
TASK_TEMPLATES = [
  "Design the data model", "Write the service object", "Add controller actions",
  "Build the UI", "Wire up the Stimulus controller", "Add request specs",
  "Add cucumber scenarios", "Update the documentation", "Handle edge cases",
  "Add i18n strings", "Refactor for clarity", "Add input validations",
  "Add background job", "Add the webhook handler", "Performance pass"
].freeze
TASK_ESTIMATES = %w[1h 2h 3h 4h 6h 1d].freeze

# Completion fraction is driven by the ticket's status so the data looks real.
def completion_fraction(status)
  case status
  when "done", "closed"       then 1.0
  when "in_review", "testing" then 0.8
  when "in_progress"          then 0.5
  when "open"                 then 0.25
  else                             0.0 # backlog / blocked
  end
end

task_count = 0
Ticket.includes(:tasks, :project).find_each do |ticket|
  next if ticket.tasks.count >= 3 # already seeded — keep idempotent

  member = ticket.assignee || ticket.owner || ticket.project.members.to_a.sample
  target = 3 + (ticket.id % 4) # 3–6 tasks per ticket

  while ticket.tasks.count < target
    idx = ticket.id + ticket.tasks.count
    ticket.tasks.create!(
      description: TASK_TEMPLATES[idx % TASK_TEMPLATES.size],
      estimation:  TASK_ESTIMATES[idx % TASK_ESTIMATES.size],
      user:        member
    )
    task_count += 1
  end

  # Mark a status-driven fraction complete; the next one is "in progress".
  all_tasks = ticket.tasks.order(:created_at).to_a
  done_n    = (all_tasks.size * completion_fraction(ticket.status)).round
  all_tasks.each_with_index do |task, i|
    if i < done_n
      task.update!(started_at: 4.days.ago, completed_at: (3 - (i % 3)).days.ago)
    elsif i == done_n && done_n < all_tasks.size && completion_fraction(ticket.status).positive?
      task.update!(started_at: 1.day.ago) # one in-progress task
    end
  end

  ticket.recalculate_task_stats!
end
puts "  ✓ #{task_count} tasks seeded across #{Ticket.count} tickets " \
     "(#{Task.completed.count} completed)"

# ──────────────────────────────────────────────────────────────────────────────
# Sample ticket attachments (image + CSV) on a few stories
# ──────────────────────────────────────────────────────────────────────────────
require "stringio"
sample_image = USER_ICON_FILES.first
attach_csv   = "ticket_id,title,status\n1,Example export,open\n2,Another row,done\n"
attached_count = 0
Ticket.where(kind: :story).order(:id).limit(4).each do |ticket|
  next if ticket.attachments.attached?

  if sample_image && File.exist?(sample_image)
    ticket.attachments.attach(io: File.open(sample_image), filename: "mockup-#{ticket.id}.jpg", content_type: "image/jpeg")
  end
  ticket.attachments.attach(io: StringIO.new(attach_csv), filename: "report-#{ticket.id}.csv", content_type: "text/csv")
  attached_count += 1
end
puts "  ✓ sample attachments added to #{attached_count} tickets"

puts "✅ Seed complete!"
