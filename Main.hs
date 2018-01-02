{-# LANGUAGE OverloadedStrings #-}

import Web.Scotty

import Control.Concurrent.MVar
import Control.Monad.IO.Class
import qualified Data.Map as M
import Network.HTTP.Types


router :: ScottyM ()
router = do
    get "/hello" $ do
        name <- param "name"
        html $ mconcat ["<h1>Hello, ", name, "!</h1>"]
        --html "<p>Hello, world!</p>"

    get "/:name" $ do
        name <- param "name"
        html $ mconcat ["<h1>Ué, ", name, "!</h1>"]


type Day = String

type Task = String

allTasks :: M.Map Day [Task]
allTasks = M.fromList
    [ ("2018-01-01",
        [ "Lavar a louça"
        , "Pagar o contador"
        , "Fazer compras"
        , "Estudar Haskell"
        , "Ligar para o cliente"
        , "Ler um livro"
        ]
      )
    , ("2018-01-02",
        [ "Escrever um tutorial"
        , "Ligar para o Vinícius"
        , "Comprar um buquê"
        , "Tirar férias"
        , "Ir ao cinema"
        , "Visitar parentes"
        ]
      )
    , ("2018-01-03",
        [ "Ir a Igreja"
        , "Abastecer o carro"
        , "Varrer a casa"
        , "Tomar banho"
        , "Salvar o planeta"
        , "Estudar Haskell"
        ]
      )
    ]


-- TODO: Implement!
validateDay :: Day -> Bool
validateDay = const True

-- TODO: Implement!
validateTasks :: [Task] -> Bool
validateTasks = const True

main :: IO ()
main = do
    tasks' <- liftIO $ newMVar allTasks

    scotty 3000 $ do
        -- Retorna todas as tarefas.
        get "/tasks" $ do
            tasks <- liftIO $ readMVar tasks'
            json tasks

        -- Recupera as tarefas de um dia.
        -- Ex: GET /tasks/2018-01-01
        get "/tasks/:day" $ do
            tasks <- liftIO $ readMVar tasks'
            day <- param "day"
            json $ M.lookup day tasks

        -- Cadastra novas tarefas no dia especificado.
        post "/tasks/:day" $ do
            day <- param "day"
            newTasks <- jsonData
            if not (validateDay day && validateTasks newTasks)
               then status status400
               else do
                   created <- liftIO $ modifyMVar tasks' $ \tasks ->
                       if M.member day tasks
                          then return (tasks, False) 
                          else return (M.insert day newTasks tasks, True) 
                   if created
                      then status status200
                      else status status403

        -- Atualiza a lista de tarefas do dia especificado.
        put "/tasks/:day" $ do
            day <- param "day"
            newTasks <- jsonData
            if not (validateDay day && validateTasks newTasks)
               then status status400
               else do
                   updated <- liftIO $ modifyMVar tasks' $ \tasks ->
                       if M.member day tasks
                          then return (M.update (\_ -> Just newTasks) day tasks, True) 
                          else return (tasks, False) 
                   if updated
                      then status status200
                      else status status404

        -- Exclui todas as tarefas do dia especificado.
        delete "/tasks/:day" $ do
            day <- param "day"
            liftIO $ modifyMVar_ tasks' $ \tasks ->
                return $ M.delete day tasks

