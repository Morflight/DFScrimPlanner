# Features

## Project Intent

DFScrimPlanner helps Delta Force teams coordinate 3-hour practice scrims. Team leaders input their team's availability windows; the app finds overlapping slots and matches teams together. Scrim organizers can search by time (then pick teams) or by teams (then find a common time). Solo players can register as fillers for teams that need a substitute.

## Feature List

| Feature | Description | Status |
|---------|-------------|--------|
| Invite-based registration | Users join via email invite link; accounts activate on first sign-in | done |
| Team management | Leaders create teams, invite teammates by email, manage roster | done |
| Member invite | Leaders AND active members can invite teammates by email | done |
| Teammate account activation | Teammates receive invite; activate account, set username/timezone/password | done |
| Password creation UI | `/register` page lets invited users set their password after clicking invite link | done |
| Forgot password | `/forgot-password` sends reset email; `/reset-password` lets user set a new password | done |
| Password visibility toggle | Eye button on all password fields (login, register, reset-password) | done |
| Admin user management | Admins can invite users with any role and view all registered users at `/admin/users` | done |
| Availability input | Users set availability windows; stored in UTC, displayed in user's local timezone | done |
| Filler registration | Solo players can register without joining a team, visible to leaders as available fillers | done |
| Filler search | Leaders can search for fillers available on a given date/time range | done |
| Time-first scrim planner | Organizer picks a time slot → app shows which teams are available | done |
| Teams-first scrim planner | Organizer picks opponent teams; own team always visible on calendar; overlap shown with opponents | done |
| Scrim-aware availability | Existing non-cancelled scrims subtract from team availability on planner and show as amber stripes on availability grid | done |
| Availability grid UI | Clean shadcn-based visual grid showing team/player availability at a glance | done |
| Timezone support | Each user stores their timezone; all comparisons done in UTC, display in local time | done |
| Week start preference | Calendars start on Monday (EU/APAC default) or Sunday (NA default); toggle in profile | done |

## Out of Scope

- In-app chat or messaging
- Automated scrim scheduling (organizer always confirms)
- Payment or premium tiers (at launch)
- Mobile app
