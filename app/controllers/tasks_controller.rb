# typed: strict
require "sorbet-runtime"

class TasksController < ApplicationController
  extend T::Sig

  @tasks = T.let(nil, T.nilable(ActiveRecord::Relation))
  @task = T.let(nil, T.nilable(Task))

  before_action :set_task, only: %i[show edit update destroy]

  sig { void }
  def index
    @tasks = T.let(Task.all, T.nilable(ActiveRecord::Relation))
  end

  sig { void }
  def show
  end

  sig { void }
  def new
    @task = T.let(Task.new, T.nilable(Task))
  end

  sig { void }
  def create
    @task = T.let(Task.new(task_params), T.nilable(Task))
    if T.must(@task).save
      redirect_to task_path(T.must(@task)), notice: "Task was successfully created."
    else
      render :new
    end
  end

  sig { void }
  def edit
  end

  sig { void }
  def update
    if T.must(@task).update(task_params)
      redirect_to task_path(T.must(@task)), notice: "Task was successfully updated."
    else
      render :edit
    end
  end

  sig { void }
  def destroy
    T.must(@task).destroy
    redirect_to tasks_path, notice: "Task was successfully destroyed."
  end

  private

  sig { void }
  def set_task
    @task = T.let(current_user.tasks.find(params[:id]), T.nilable(Task))
  end

  sig { returns(ActionController::Parameters) }
  def task_params
    params.require(:task).permit(:title, :description, :completed)
  end

  sig { params(task: Task).returns(String) }
  def task_path(task)
    Rails.application.routes.url_helpers.task_path(task)
  end

  sig { returns(String) }
  def tasks_path
    Rails.application.routes.url_helpers.tasks_path
  end
end
