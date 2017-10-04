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
        @papersize =  GlobalProperty.find("paper_size") rescue nil
				if @papersize.blank?
          GlobalProperty.create(property: "paper_size", value: params[:property][:paper_size], uuid: SecureRandom.uuid)
          flash[:notice] = "Set paper size"
				else
          @papersize.update_attributes(value: params[:property][:paper_size])
				  flash[:notice] = "Changed paper size"
				end
			
    elsif admin_password.present? && signatory_password.present? && signatory_username.present?
        raise User.current.inspect
        user = User.current_user
      
        if user.role.downcase == "system administrator" && user.password_matches?(admin_password)
       
          signatory = User.find(signatory_username)
         
          if signatory.present?
        
           if signatory.role.downcase == "certificate signatory" && signatory.password_matches?(signatory_password)
              @signatory =  GlobalProperty.find("signatory") rescue nil
							if @signatory.blank?
								GlobalProperty.create(setting: "signatory", value: signatory_username)
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
