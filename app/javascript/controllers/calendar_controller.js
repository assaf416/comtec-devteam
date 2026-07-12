import { Controller } from "@hotwired/stimulus"
import { Calendar } from "@fullcalendar/core"
import dayGridPlugin from "@fullcalendar/daygrid"
import timeGridPlugin from "@fullcalendar/timegrid"
import listPlugin from "@fullcalendar/list"

export default class extends Controller {
    static values = {
        eventsUrl: String,
        initialView: { type: String, default: "dayGridMonth" }
    }

    connect() {
        this.calendar = new Calendar(this.element, {
            plugins: [dayGridPlugin, timeGridPlugin, listPlugin],
            initialView: this.initialViewValue,
            headerToolbar: {
                left: "prev,next today",
                center: "title",
                right: "dayGridMonth,timeGridWeek,listMonth"
            },
            events: this.eventsUrlValue,
            height: "auto",
            eventClick(info) {
                if (info.event.url) {
                    info.jsEvent.preventDefault()
                    window.location.href = info.event.url
                }
            },
            eventDidMount(info) {
                const type = info.event.extendedProps.type
                const project = info.event.extendedProps.project
                let tooltip = info.event.title
                if (project) tooltip += ` — ${project}`
                info.el.title = tooltip
                info.el.dataset.bsToggle = "tooltip"
            }
        })
        this.calendar.render()
    }

    disconnect() {
        this.calendar?.destroy()
    }
}
