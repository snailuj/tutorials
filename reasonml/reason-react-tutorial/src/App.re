/* reducerComponent requires this */
type repository = {
  name: string,
  description: string,
  href: string,
};

type state = {
    input: string,
    isLoading: bool,
    results: list(repository),
};

/* reducerComponent requires this */
type action = 
    | UpdateInput(string)
    | UpdateResults(list(repository))
    | Search;

let component = ReasonReact.reducerComponent("App");

module Api = {
  open Json.Decode;

  let decodeResults = 
    field(
      "items",
      list(
        optional(json =>
          {
            name: field("name", string, json),
            description: field("description", string, json),
            href: field("html_url", string, json),
          }
        ),
      ),
    );

  let getResults = query =>
    /* This is a "local" open, it makes the Js.Promise module available inside of 
       the parentheses */
    Js.Promise.(
      Fetch.fetch("https://api.github.com/search/repositories?q=" ++ query)
      |> then_(Fetch.Response.json)
      |> then_(json => decodeResults(json) |> resolve)
      |> then_(results =>
        results
        /* Filter out items that failed to decode */
        |> List.filter(optionalItem => 
            switch(optionalItem) {
            | Some(_) => true
            | None => false
            }
          )
        /* Unpack items from the option type */
        |> List.map(item =>
            switch(item) {
              | Some(item) => item
            }
          )
        |> resolve
        )
    )
};

let make = _children => {
  ...component,

  /* 
   * reducerComponent requires this 
   * Has to return the same `state` type defined above
   */
  initialState: () => {
      input: "",
      isLoading: false,
      results: [],
  },

  /*
   * reducerComponent requires this
   * reducer() works exactly the same as a Redux reducer -- it takes an action 
   * and state as arguments and returns an update to the state. Technically
   * it returns a special update type that manages the setState that you would
   * normally do in JavaScript. However, the argument to the update type is the
   * next state that you would like your component to have, so we can just think
   * about the reducer as returning the updated state.`
   */
  reducer: (action, state) => 
      switch(action) {
          | UpdateInput(newInput) => ReasonReact.Update({...state, input: newInput})
          | UpdateResults(results) => ReasonReact.Update({...state, isLoading: false, results: results})
          /*
           * We need to modify the Search part of our reducer to use ReasonReact.UpdateWithSideEffects
           * instead of just ReasonReact.Update. This function updates the state, and then triggers a
           * "side effect". We can do *whatever* we want in those side effects, so this will be perfect
           * for allowing us to trigger an API request and add some loading state after the form is
           * submitted.
           */ 
          | Search => 
            ReasonReact.UpdateWithSideEffects(
              {...state, isLoading: true},
              (
                /* the side effect callback is given `self` as an argument */
                self => {
                  let value = self.state.input;
                  /* we need to bind the result of `getResults` even though we don't want it
                   * because otherwise it will be taken as the return value of this side-effect cb
                   * and we need to return unit () from this function, not Promise */
                  let _ = Api.getResults(value)
                    |> Js.Promise.then_(results => {
                      self.send(UpdateResults(results))
                      Js.Promise.resolve();
                    });
                  /* the side-effect cb must return a unit () type */
                  ();
                }
              )
            )
      },
  
  render: self =>
    <div>
      <form onSubmit={
        ev => {
          ReactEvent.Form.preventDefault(ev);
          self.send(Search);
        }
      }>
        <label htmlFor="search"> "search"->ReasonReact.string </label>
        <input 
          id="search" 
          name="search" 
          value=self.state.input 
          onChange={ev => {
            let value = ReactEvent.Form.target(ev)##value
            self.send(UpdateInput(value))
          }}/>
        <button type_="submit">
          "Submit Search"->ReasonReact.string
        </button>
      </form>
      <div>
        {
          self.state.isLoading ? 
            "Loading..."->ReasonReact.string : 
            self.state.results
            /* Convert list to an array for ReasonReact */
            |> Array.of_list
            /* Map each array item to a <Card /> component */
            |> Array.map(({name, href, description}) =>
                <Card key={href} name href description />
            )
            /* Transform the array into a valid React node, similar to ReasonReact.string */
            |> ReasonReact.array
        }
      </div>
    </div>,
};