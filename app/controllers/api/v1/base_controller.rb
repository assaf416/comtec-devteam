module Api
  module V1
    class BaseController < ApplicationController
      protect_from_forgery with: :null_session
      skip_before_action :authenticate_user!
      before_action :authenticate_api_user!

      private

      def authenticate_api_user!
        token = request.headers["Authorization"]&.sub(/\ABearer\s+/, "")
        @current_api_user = User.find_by(api_token: token) if token.present?
        render json: { error: "Unauthorized" }, status: :unauthorized unless @current_api_user
      end

      def current_api_user
        @current_api_user
      end

      def render_ticket(ticket)
        {
          id:                    ticket.id,
          title:                 ticket.title,
          description:           ticket.description,
          status:                ticket.status,
          priority:              ticket.priority,
          kind:                  ticket.kind,
          level:                 ticket.level,
          how_to_reproduce:      ticket.how_to_reproduce,
          test_plan:             ticket.test_plan,
          story_points:          ticket.story_points,
          actual_velocity:       ticket.actual_velocity,
          pr_number:             ticket.pr_number,
          pr_url:                ticket.pr_url,
          dev_estimate_hours:    ticket.dev_estimate_hours,
          tester_estimate_hours: ticket.tester_estimate_hours,
          actual_hours:          ticket.actual_hours,
          project: {
            id:   ticket.project_id,
            name: ticket.project.name,
            repo_url: ticket.project.repo_url,
            default_branch: ticket.project.default_branch
          },
          assignee: ticket.assignee && { id: ticket.assignee_id, name: ticket.assignee.display_name },
          owner:    ticket.owner    && { id: ticket.owner_id,    name: ticket.owner.display_name },
          estimated_by: ticket.estimated_by && { id: ticket.estimated_by_id, name: ticket.estimated_by.display_name },
          branch_name: ticket.branch_name,
          github_issue_number: ticket.github_issue_number,
          github_url:          ticket.github_url,
          created_at: ticket.created_at,
          updated_at: ticket.updated_at
        }
      end

      def render_pull_request(pull_request)
        {
          id: pull_request.id,
          title: pull_request.title,
          description: pull_request.description,
          status: pull_request.status,
          pr_number: pull_request.pr_number,
          author: pull_request.author,
          gitea_url: pull_request.gitea_url,
          source_files: pull_request.source_files,
          test_files: pull_request.test_files,
          synced_at: pull_request.synced_at,
          build_errors: pull_request.build_errors,
          latest_test_results: pull_request.latest_test_results,
          project: {
            id: pull_request.project_id,
            name: pull_request.project.name
          },
          ticket: pull_request.ticket && {
            id: pull_request.ticket_id,
            title: pull_request.ticket.title,
            branch_name: pull_request.ticket.branch_name
          },
          created_at: pull_request.created_at,
          updated_at: pull_request.updated_at
        }
      end

      def render_test_result(test_result)
        {
          id: test_result.id,
          suite_name: test_result.suite_name,
          total: test_result.total,
          passed: test_result.passed,
          failed: test_result.failed,
          skipped: test_result.skipped,
          duration_ms: test_result.duration_ms,
          xml_report: test_result.xml_report,
          created_at: test_result.created_at,
          updated_at: test_result.updated_at
        }
      end

      def render_ci_run(ci_run)
        {
          id: ci_run.id,
          build_number: ci_run.build_number,
          status: ci_run.status,
          branch_name: ci_run.branch_name,
          commit_sha: ci_run.commit_sha,
          log_url: ci_run.log_url,
          started_at: ci_run.started_at,
          finished_at: ci_run.finished_at,
          duration_minutes: ci_run.duration,
          project: {
            id: ci_run.project_id,
            name: ci_run.project.name
          },
          ticket: ci_run.ticket && {
            id: ci_run.ticket_id,
            title: ci_run.ticket.title
          },
          triggered_by: ci_run.triggered_by && {
            id: ci_run.triggered_by_id,
            name: ci_run.triggered_by.display_name
          },
          test_results: ci_run.test_results.order(:id).map { |result| render_test_result(result) },
          created_at: ci_run.created_at,
          updated_at: ci_run.updated_at
        }
      end

      def render_deployment(deployment)
        {
          id: deployment.id,
          version: deployment.version,
          environment: deployment.environment,
          status: deployment.status,
          deploy_type: deployment.deploy_type,
          machine_name: deployment.machine_name,
          notes: deployment.notes,
          env_vars: deployment.env_vars,
          deployed_at: deployment.deployed_at,
          project: {
            id: deployment.project_id,
            name: deployment.project.name
          },
          deployed_by: deployment.deployed_by && {
            id: deployment.deployed_by_id,
            name: deployment.deployed_by.display_name
          },
          client_account: deployment.client_account && {
            id: deployment.client_account_id,
            name: deployment.client_account.name
          },
          created_at: deployment.created_at,
          updated_at: deployment.updated_at
        }
      end

      def render_user(user)
        {
          id:         user.id,
          name:       user.display_name,
          email:      user.email,
          role:       user.role,
          phone:      user.phone,
          avatar_url: (user.avatar.attached? ? rails_blob_path(user.avatar) : nil),
          created_at: user.created_at,
          updated_at: user.updated_at
        }
      end

      def render_project(project)
        {
          id:             project.id,
          name:           project.name,
          repo_url:       project.repo_url,
          default_branch: project.default_branch,
          tech_stack:     project.tech_stack,
          active:         project.active,
          members:        project.members.order(:name).map { |u| { id: u.id, name: u.display_name, email: u.email } },
          created_at:     project.created_at,
          updated_at:     project.updated_at
        }
      end

      def render_attachment(attachment)
        {
          id:                attachment.id,
          title:             attachment.title,
          filename:          attachment.filename,
          content_type:      attachment.content_type,
          byte_size:         attachment.byte_size,
          extraction_status: attachment.extraction_status,
          project: {
            id:   attachment.project_id,
            name: attachment.project.name
          },
          attachable: attachment.attachable_type && {
            type: attachment.attachable_type,
            id:   attachment.attachable_id
          },
          uploaded_by: attachment.uploaded_by && {
            id:   attachment.uploaded_by_id,
            name: attachment.uploaded_by.display_name
          },
          download_url: attachment.file.attached? ? rails_blob_path(attachment.file) : nil,
          created_at:   attachment.created_at,
          updated_at:   attachment.updated_at
        }
      end

      def normalized_env_vars(rows)
        Array(rows).filter_map do |row|
          key = row[:key].presence || row["key"].presence
          value = row[:value].presence || row["value"].presence
          next if key.blank? && value.blank?

          { key: key.to_s, value: value.to_s }
        end
      end
    end
  end
end
