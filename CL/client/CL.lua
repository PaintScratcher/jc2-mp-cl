class 'CL'

function CL:__init()
    Events:Subscribe( "ModuleLoad", self, self.ModulesLoad )
    Events:Subscribe( "ModulesLoad", self, self.ModulesLoad )
end

function CL:ModulesLoad()
    Events:FireRegisteredEvent( "HelpAddItem",
        {
            name = "CL",
            text = 
                "JC2-MP Module 'CL' by Chris Lewis and Adam Taylor\n\n" ..
				"Source available at http://github.com/C-D-Lewis/jc2-mp-cl\n\n" ..
				"/help for list of commands" 
        } )
end

CL = CL()