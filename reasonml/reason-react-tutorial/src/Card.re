let component = ReasonReact.statelessComponent("Card");

module Styles = {
    open Css;
    let card = style([
        border(px(1), `solid, hex("898989")),
        borderRadius(px(4)),
        padding(rem(1.0))
    ])
}

let make = (~name, ~description, ~href, _children) => {
    ...component,
    /* statelessComponent requires this */
    render: _self => 
        <div className=Styles.card>
            <h3>
                <a href target="_blank" rel="noopener noreferrer">
                    {name->ReasonReact.string}
                </a>
            </h3>
            <p> {description->ReasonReact.string} </p>
        </div>,
};