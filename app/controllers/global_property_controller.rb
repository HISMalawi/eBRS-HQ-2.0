class GlobalPropertyController < ApplicationController

  def paper
    @property = GlobalProperty.new
    @papersize =  GlobalProperty.find_by_property("paper_size").value rescue nil
  end

  def signature
    @property = GlobalProperty.new
    @signatory =  GlobalProperty.find_by_property("signatory").value rescue nil
  end

  def set_property
    papersize = params[:property][:paper_size] rescue nil
    admin_password = params[:global_property][:admin_password] rescue nil
    signatory_password = params[:global_property][:signatory_password] rescue nil
    signatory_username = params[:global_property][:value] rescue nil
    
    #setting paper_size
    if papersize.present?
        @papersize =  GlobalProperty.find_by_property("paper_size") rescue nil
				if @papersize.blank?
          GlobalProperty.create(property: "paper_size", value: params[:property][:paper_size], uuid: SecureRandom.uuid)
          flash[:notice] = "Set paper size"
				else
          @papersize.update_attributes(value: params[:property][:paper_size])
				  flash[:notice] = "Changed paper size"
				end
			
    elsif admin_password.present? && signatory_password.present? && signatory_username.present?
        user =  User.current
        user_role = UserRole.find_by_user_id(user.id)
        if user_role.role.role == "Administrator" && user.password_matches?(admin_password)
          signatory = User.find_by_username(signatory_username)
          if signatory.present?
           signatory_role = UserRole.find_by_user_id(signatory.id)
           if signatory_role.role.role == "Certificate Signatory" && signatory.password_matches?(signatory_password)
              @signatory =  GlobalProperty.find_by_property("signatory") rescue nil
							if @signatory.blank?
								GlobalProperty.create(property: "signatory", value: signatory_username, uuid: SecureRandom.uuid)
								flash[:notice] = "Assigned signatory"
							else
								@signatory.update_attributes(value: signatory_username)
								flash[:notice] = "Updated signatory"
							end
           else
           	flash[:error] = "Wrong signatory or wrong signatory password"
           end
          
          else
           flash[:error] = "Unauthorised user" 
          end
        else
          flash[:error] = "Unauthorised user"
        end
        
    end
    
    redirect_to "/" and return	
    
  end

end
