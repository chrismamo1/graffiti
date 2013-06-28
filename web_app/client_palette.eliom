
{client{

  open Lwt

  (** Handle client palette action **)
  let start body_elt canvas_elt palette_div palette_button
      slider color_picker color_div =

    (*** Elements ***)

    let dom_palette = Eliom_content.Html5.To_dom.of_div palette_div in
    let dom_button_palette = Eliom_content.Html5.To_dom.of_td palette_button in
    let dom_canvas = Eliom_content.Html5.To_dom.of_canvas canvas_elt in
    let dom_color = Eliom_content.Html5.To_dom.of_div color_div in
    let width, height = Client_tools.get_size dom_canvas in
    let base_size = min width height in

    (* Elarge color picker on computer *)
    let color_picker' = if (not (Client_mobile.has_small_screen ()))
      then Grf_color_picker.add_square_color color_picker
        Grf_color_picker.lll_color_6
      else color_picker
    in

    let color_square_list =
      Grf_color_picker.get_square_color_div_list color_picker'
    in
    let dom_color_list = List.map
      (fun elt -> Eliom_content.Html5.To_dom.of_div elt) color_square_list
    in
    let nb_square_row = (List.length color_square_list) / 2 in

    (* Add listenner of touch events on small screen *)
    (* for palette menu *)
    let button () =
      let contract_menu = ref true in
      Lwt.async (fun () -> Lwt_js_events.clicks dom_button_palette
        (fun _ _ ->
          (if not !contract_menu
           then (contract_menu := true;
                 Client_tools.progressive_apply 0 (-196))
           else (contract_menu := false;
                 Client_tools.progressive_apply (-196) 0))
            (fun v ->
              dom_palette##style##left <- Client_menu_tools.js_string_of_px v)))
    in Client_mobile.launch_only_on_small_screen button;

    (* Add listenner of resize event *)

    (* on color square *)
    (* calcul and resize square color to take the maximum of space *)
    let handle_color_square_resize () =
      let margin = 8 in
      let body_height = Dom_html.document##documentElement##clientHeight in
      let new_height = (body_height - (margin * 2)) / nb_square_row in
      let rec aux = function
        | []            -> ()
        | dom_div::tail ->
          dom_div##style##height <- Js.string
            (string_of_int (new_height) ^ "px");
          aux tail
      in aux dom_color_list
    in handle_color_square_resize (); (* To initialize view *)
    Lwt.async (fun () -> Client_tools.limited_onorientationchanges_or_onresizes
      (fun _ _ -> Lwt.return (handle_color_square_resize ())));

    (* catch slider move and click *)
    let handler () =
      let brush_size = Js.string (string_of_int
        (int_of_float (
          ((Client_ext_mod_tools.get_slider_value slider) *.
            (float_of_int base_size)))) ^ "px")
      in
      dom_color##style##width <- brush_size;
      dom_color##style##height <- brush_size;
      Lwt.return ()
    in
    Grf_slider.change_move_slide_callback slider handler;
    Grf_slider.change_click_callback slider handler;

    (* start slider script *)
    Grf_slider.start slider;

    (* Start color picker stript *)
    Grf_color_picker.start color_picker'

}}
