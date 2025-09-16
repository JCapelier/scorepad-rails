import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

// Loads every *_controller.js in app/javascript/controllers
eagerLoadControllersFrom("controllers", application)
