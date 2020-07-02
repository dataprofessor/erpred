library(randomForest)
library(data.table)

shinyServer(function(input, output, session) {
  
  # Loads the Model to memory
  ER_alpha <- file.path("ER_alpha_RF_int.rds")
  ER_beta <- file.path("ER_beta_RF_int.rds")
  ER_alpha.RF <- readRDS(ER_alpha)
  ER_alpha.RF <- readRDS(ER_beta)
  
  # Retrieving the descriptor names from trained model data
  ER_alpha_internal <- readRDS("ER_alpha_FP_PubchemFingerprinter_internal.rds")
  ER_beta_internal <- readRDS("ER_beta_FP_PubchemFingerprinter_internal.rds")
  
  ER_alpha.desc.name <- data.frame(rownames(ER_alpha.RF$importance))
  ER_alpha.desc.name <- t(ER_alpha.desc.name)
  names(ER_alpha.desc.name) <- as.character(unlist(ER_alpha.desc.name[1,]))
  
  ER_beta.desc.name <- data.frame(rownames(ER_beta.RF$importance))
  ER_beta.desc.name <- t(ER_beta.desc.name)
  names(ER_beta.desc.name) <- as.character(unlist(ER_beta.desc.name[1,]))
  
  observe({
    
    shinyjs::hide("downloadData") # Hide download button before input submission
    if(input$submitbutton>0)
      shinyjs::show("downloadData") # Show download button after input submission
  })
  
  observe({
    COMPOUNDDATA <- ''
    compoundexample <- 'Oc1ccc2C3=C(CCOc2c1)c4ccc(O)cc4O[C@H]3c5ccc(OCCN6C(=O)CCC6=O)cc5  CHEMBL1088337
C[C@]12CC[C@H]3[C@@H](CCc4cc(O)ccc34)[C@@H]1CC[C@@]2(O)c5ccc6COCc6c5  CHEMBL1097377
CCOC(=O)C1(Cc2ccc(cc2C1)[C@]3(O)CC[C@H]4[C@@H]5CCc6cc(O)ccc6[C@H]5CC[C@]34C)C#N CHEMBL1098710
FC(F)Oc1ccc(cc1)c2oc(SCC(=O)NC(=O)NCc3occc3)nn2 CHEMBL1303477
COc1ccc2c(c1)C(=O)Oc3cc(OCC(=O)NC4CCCCC4)ccc23  CHEMBL1325233
CN1N=C(c2c(c(N)n(C3CCCCC3)c2C1=O)c4nc5ccccc5s4)[N+](=O)[O-] CHEMBL1326210
'
    
    if(input$addlink>0) {
      isolate({
        COMPOUNDDATA <- compoundexample
        updateTextInput(session, inputId = "Sequence", value = COMPOUNDDATA)
      })
    }
  })
  
  datasetInput <- reactive({
    
    inFile <- input$file1 
    inTextbox <- input$Sequence
    
    if (is.null(inTextbox)) {
      return("Please insert/upload molecules in SMILES notation")
    } else {
      if (is.null(inFile)) {
        # Read data from text box
        x <- inTextbox
        write.table(x, sep="\t", file = "text.smi", col.names=FALSE, row.names=FALSE, quote=FALSE)
        #x <- read.table("text.smi")
        
        
        # PADEL descriptors for Testing set
        
        #test <- x
        
        try(system("bash PADEL.sh", intern = TRUE, ignore.stderr = TRUE))
        #desc.df <- read.csv("descriptors_output.csv")
        ER_alpha.desc.df <- read.csv("descriptors_output.csv")
        ER_alpha.desc.df2 <- ER_alpha.desc.df[,( names(ER_alpha.desc.df) %in% ER_alpha.desc.name )]
        ER_alpha.mol.desc = data.frame(ER_alpha.desc.df2)
        
        ER_beta.desc.df <- read.csv("descriptors_output.csv")
        ER_beta.desc.df2 <- ER_beta.desc.df[,( names(ER_beta.desc.df) %in% ER_beta.desc.name )]
        ER_beta.mol.desc = data.frame(ER_beta.desc.df2)
   
        # Predicting unknown sequences
        ER_alpha.prediction <- data.frame(Prediction= predict(ER_alpha.RF,ER_alpha.mol.desc), round(predict(ER_alpha.RF,ER_alpha.mol.desc,type="prob"),3))
        ER_beta.prediction <- data.frame(Prediction= predict(ER_beta.RF,ER_beta.mol.desc), round(predict(ER_beta.RF,ER_beta.mol.desc,type="prob"),3))
        compoundname <- data.frame(ER_alpha.desc.df$Name)
        row.names(compoundname) <- ER_alpha.desc.df$Name
        results <- cbind(compoundname, ER_alpha.prediction, ER_beta.prediction)
        #names(results)[1] <- "Name"
        names(results) <- c("Name","ERa.prediction","ERa.active","ERa.inactive","ERb.prediction","ERb.active","ERb.inactive")
        results <- data.frame(results, row.names=NULL)
        
        print(results)
      } 
      else {  
        # Read data from uploaded file
        x <- read.table(inFile$datapath)
        
        # PADEL descriptors for Testing set
        
        test <- x
        
        try(system("bash PADEL.sh", intern = TRUE, ignore.stderr = TRUE))
        #desc.df <- read.csv("descriptors_output.csv")
        ER_alpha.desc.df <- read.csv("descriptors_output.csv")
        ER_alpha.desc.df2 <- desc.df[,( names(desc.df) %in% desc.name )]
        
        ER_alpha.mol.desc = data.frame(desc.df2)
        
        # Predicting unknown sequences
        ER_alpha.prediction <- data.frame(Prediction= predict(RFalpha,ER_alpha.mol.desc), round(predict(RFalpha,ER_alpha.mol.desc,type="prob"),3))
        ER_beta.prediction <- data.frame(Prediction= predict(RFbeta,ER_beta.mol.desc), round(predict(RFbeta,ER_beta.mol.desc,type="prob"),3))
        compoundname <- data.frame(ER_alpha.mol.desc$Name)
        row.names(compoundname) <- ER_alpha.mol.desc$Name
        results <- cbind(compoundname, ER_alpha.prediction, ER_beta.prediction)
        names(results) <- c("Name","ERa.prediction","ERa.active","ERa.inactive","ERb.prediction","ERb.active","ERb.inactive")
        results <- data.frame(results, row.names=NULL)
        
        print(results)
      }
    }
  })
  
  output$contents <- renderPrint({
    if (input$submitbutton>0) { 
      isolate(datasetInput()) 
    } else {
      return("Server is ready for prediction.")
    }
  })
  
  output$downloadData <- downloadHandler(
    filename = function() { paste('predicted_results', '.csv', sep='') },
    content = function(file) {
      write.csv(datasetInput(), file, row.names=FALSE)
    })
  
})