require File.dirname(__FILE__) + '/../test_helper'
require 'participants_controller'

class ParticipantsController; def rescue_action(e) raise e end; end

class ParticipantsControllerTest < ActionController::TestCase
  fixtures :participants
  fixtures :courses
  fixtures :assignments
  fixtures :users
  fixtures :response_maps
  fixtures :teams_users

  def setup
=begin
    @participant = Participant.new(
        :submit_allowed => 1, :review_allowed => 1, :user_id =>1, :parent_id => 1,
        :penalty_accumulated => 0, :type => "AssignmentParticipant", :handle => "par1", :submitted_hyperlinks => "--- \n- http://www.ncsu.edu/\n- http://www.google.com/\n" )

    #@assignment = assignments(:assignment_project1)

    #@participant.save
=end
    @model = Participant
    @controller = ParticipantsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @request.session[:user] = User.find(users(:superadmin).id )
    roleid = User.find(users(:superadmin).id).role_id
    Role.rebuild_cache

    Role.find(roleid).cache[:credentials]
    @request.session[:credentials] = Role.find(roleid).cache[:credentials]
    # Work around a bug that causes session[:credentials] to become a YAML Object
    @request.session[:credentials] = nil if @request.session[:credentials].is_a? YAML::Object
    @settings = SystemSettings.find(:first)
    AuthController.set_current_role(roleid,@request.session)

    @User = participants(:par15)
  end

  test "should add new participant" do
    assert_difference('Participant.count') do
      @participant = Participant.new(
          :submit_allowed => 1, :review_allowed => 1, :user_id =>20, :parent_id => 1,
          :penalty_accumulated => 0, :type => "AssignmentParticipant", :handle => "par20", :submitted_hyperlinks => "--- \n- http://www.ncsu.edu/\n- http://www.google.com/\n"
      )
      @participant.save
    end
    #assert_not_nil(@participant)
    #assert_response :success
    #assert_redirected_to :action => 'list', :id => @participant.id
  end

=begin
  test "should enter the rescue block" do
    @user = User.new(
        :name => "instructor3", :fullname => "instructor3_fullname",
        :email => "instr3@mailinator.com", :email_on_review => 1,
        :email_on_submission => 1, :email_on_review => 1
    )
    #@participant = participants(:par0)
    @participant = Participant.new(
        :submit_allowed => 1, :review_allowed => 1, :user_id =>20, :parent_id => 1,
        :penalty_accumulated => 0, :type => "AssignmentParticipant", :handle => "par20", :submitted_hyperlinks => "--- \n- http://www.ncsu.edu/\n- http://www.google.com/\n"
    )
    #assert_nil(@User)
    post :add, :id => @participant.id, :user => :par15, :name => "newuser"
    assert_not_equal "blah blah", flash[:error]
  end
=end

  test "testing redirect for delete_items" do
    @participant = participants(:par2)
    @response_map = response_maps(:response_maps1)
    @teams_users = teams_users(:teams_users1)
    post :delete_items, :id => @participant.id, :ResponseMap => @response_map.id, :TeamsUser => @teams_users.id
    assert_response :redirect
    assert_redirected_to :action => 'delete', :id => @participant.id, :method => :post
  end

  test "redirect test for delete participant" do
    @participant = participants(:par2)
    #numParticipants = Participant.count
    #assert_difference('Participant.count', 1) do
    post :delete, :force => 1, :id => @participant.id
    #assert_equal numParticipants-1, Participant.count
    #assert_equal "#{@participant.name} has been removed as a participant." , flash[:note]
    assert_redirected_to :controller => 'participants', :action => 'list', :id => @participant.parent_id, :model => "Assignment"
    #end
  end

  test "testing_bequeath_all_with_valid_input_with_redirect" do
    @assignment = assignments(:assignment0)
    @course = @assignment.course
    post :bequeath_all , :id => @assignment.id
    assert_equal "All participants were successfully copied to \""+@course.name+"\"", flash[:note]
    assert_redirected_to :controller => 'participants', :action => 'list', :id => @assignment.id, :model => 'Assignment'
  end

  test "testing_bequeath_all_with_invalid_input_with_redirect" do
    @assignment = assignments(:assignment_project1)
    @course = @assignment.course
    post :bequeath_all , :id => @assignment.id
    assert_equal "This assignment is not associated with a course.", flash[:error]
    assert_redirected_to :controller => 'participants', :action => 'list', :id => @assignment.id, :model => 'Assignment'
  end

  test "should inherit with valid input and redirect" do
    @assignment = assignments(:assignment1)
    post :inherit, :id => @assignment.id
    @course = @assignment.course
    @participant = @course.participants
    assert(@participant.length)
    #assert_equal "No participants were found to inherit", flash[:note]
    #assert_equal "No course was found for this assignment.", flash[:error]
    assert_redirected_to :controller => 'participants', :action => 'list', :id => @assignment.id, :model => 'Assignment'
  end

  test "should inherit with invalid input and redirect" do
    @assignment = assignments(:assignment_project1)
    post :inherit, :id => @assignment.id
    @course = @assignment.course
    #assert_equal "No participants were found to inherit", flash[:note]
    assert_equal "No course was found for this assignment.", flash[:error]
    assert_redirected_to :controller => 'participants', :action => 'list', :id => @assignment.id, :model => 'Assignment'
  end

=begin
  test "should not change handle" do
      @participant = participants(:par15)
      post :change_handle, :id => @participant.id, :handle => "par15", :participant => @participant
      #assert_equal "<b>#{@participant.handle}</b> is already in use for this assignment. Please select a different handle.", flash[:error]
      assert_redirected_to :controller => 'student_task', :action => 'view', :id => @participant
      assert_redirected_to :controller => 'participants', :action => 'change_handle', :id => @participant
  end
=end

  test "delete_assignment_participant_with_valid_input" do
    @participant = participants(:par0)
    @name = @participant.name
    @assignment_id = @participant.assignment
    post :delete_assignment_participant , :id => @participant.id
    assert_equal flash[:note] , "\"#{@name}\" is no longer a participant in this assignment."
    #assert_equal flash[:error] = "\"#{@name}\" was not removed. Please ensure that \"#{@name}\" is not a reviewer or metareviewer and try again."
    assert_redirected_to :controller => 'review_mapping', :action => 'list_mappings', :id => @assignment_id
  end

  test "delete_assignment_participant_with_invalid_input" do
    @participant = participants(:par17)
    @name = @participant.name
    @assignment_id = @participant.assignment
    post :delete_assignment_participant , :id => @participant.id
    #assert_equal flash[:note] , "\"#{@name}\" is no longer a participant in this assignment."
    assert_equal "was not removed. Please ensure that  is not a reviewer or metareviewer and try again.", flash[:error]
    assert_redirected_to :controller => 'review_mapping', :action => 'list_mappings', :id => @assignment_id
  end
=begin
  test "should delete items" do
    post :delete, :force => 1, :id => @assignment
    assert_redirected_to :controller => 'participants', :action => 'list', :id => @assignment, :model => 'Assignment'
  end
=end

  test "change_handle" do
    @participant = participants(:par16)


    if params[:participant] != nil
      if AssignmentParticipant.find_all_by_parent_id_and_handle(@participant.parent_id, params[:participant][:handle]).length > 0
        flash[:error] = "<b>#{params[:participant][:handle]}</b> is already in use for this assignment. Please select a different handle."
        redirect_to :controller => 'participants', :action => 'change_handle', :id => @participant
      else
        @participant.update_attributes(params[:participant])
        redirect_to :controller => 'student_task', :action => 'view', :id => @participant
      end
    end
  end




end